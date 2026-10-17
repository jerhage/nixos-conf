{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.server;

  # Apps served under a prefix need to be told what it is, or they emit
  # absolute links that escape the prefix. X-Script-Name is the werkzeug
  # convention, X-Forwarded-Prefix the more common one; both are ignored by
  # apps that do not read them.
  proxyBlock =
    name: s:
    let
      prefixHeaders = lib.optionalString (cfg.routing == "path") ''
        header_up X-Script-Name /${name}
        header_up X-Forwarded-Prefix /${name}
      '';
    in
    ''
      reverse_proxy 127.0.0.1:${toString s.port} {
        ${prefixHeaders}
        ${s.proxyConfig}
      }
    '';

  # Named matchers only work at site level, and path routing shares one block.
  corsMatchers =
    name: s:
    let
      scope = lib.optionalString (cfg.routing == "path") "path /${name} /${name}/*";
    in
    lib.optionalString (s.cors != [ ]) (
      lib.concatStringsSep "\n" (
        lib.imap0 (i: origin: ''
          @cors_${name}_${toString i} {
            ${scope}
            header Origin ${origin}
          }
        '') s.cors
      )
      + ''
        @preflight_${name} {
          ${scope}
          method OPTIONS
        }
      ''
    );

  # One block per origin: the header takes one value, and never a wildcard with cookies.
  corsHandlers =
    name: s:
    lib.optionalString (s.cors != [ ]) (
      lib.concatStringsSep "\n" (
        lib.imap0 (i: origin: ''
          header @cors_${name}_${toString i} {
            Access-Control-Allow-Origin "${origin}"
            Access-Control-Allow-Credentials "true"
            Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS"
            Access-Control-Allow-Headers "Content-Type, Authorization"
            Access-Control-Max-Age "86400"
            Vary Origin
            defer
          }
        '') s.cors
      )
      # Preflights must not get the redirect below; browsers do not follow one.
      + ''
        respond @preflight_${name} 204
      ''
    );

  # route: Caddy's own order runs redir before respond, 301-ing the preflight.
  site =
    name: s:
    if cfg.routing == "path" then
      ''
        ${corsMatchers name s}
        route {
          ${corsHandlers name s}
          redir /${name} /${name}/ 301
          handle_path /${name}/* {
            ${proxyBlock name s}
            ${s.extraConfig}
          }
        }
      ''
    else
      ''
        ${corsMatchers name s}
        route {
          ${corsHandlers name s}
          ${proxyBlock name s}
          ${s.extraConfig}
        }
      '';
in
{
  options.my.server = {
    enable = lib.mkEnableOption "Caddy fronting local services";

    routing = lib.mkOption {
      type = lib.types.enum [
        "path"
        "host"
      ];
      default = "path";
      description = ''
        How Caddy picks a service.

        `path` serves everything on one origin as /<name>/, reached through a
        single `tailscale serve --https=443 http://localhost:<listenPort>`.
        Apps must support a base-path setting or they emit broken asset links.

        `host` serves each at <name>.<domain>, so every app runs at root. Needs
        DNS for those names and a cert, which tailscale serve does not provide.
      '';
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "home.example.com";
      description = "Base domain. Only used when routing is `host`.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 80;
      description = ''
        Localhost port Caddy binds. Nothing opens this to the network: with
        `path` routing tailscale serve reaches it over loopback.
      '';
    };

    tailscaleServe = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Publish Caddy at `https://<host>.<tailnet>.ts.net/`. Otherwise this is
        a one-off command living in tailscale's state, which a reinstall drops
        silently and no error points at.
      '';
    };

    sites = lib.mkOption {
      default = { };
      description = "Services to publish, each proxied from a localhost port.";
      example = {
        books = {
          port = 8083;
        };
      };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.port;
              description = "Loopback port the service listens on. Bind the service to 127.0.0.1.";
            };
            proxyConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              example = "header_up Host {upstream_hostport}";
              description = "Directives inside this service's reverse_proxy block.";
            };
            cors = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "https://app.example.com" ];
              description = ''
                Origins allowed to call this service from browser javascript.
                Scheme and port must match what the browser sends, and only a
                browser enforces this: native clients and scripts ignore CORS
                entirely, so they need nothing here.
              '';
            };
            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Caddy directives for this service, after the proxy.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.routing == "path" -> cfg.domain == "";
        message = "my.server.domain is only meaningful when routing is \"host\".";
      }
      {
        assertion = cfg.routing == "host" -> cfg.domain != "";
        message = "my.server.routing = \"host\" needs my.server.domain.";
      }
    ];

    # Fails until `tailscale up` has run on a fresh host, hence the retry.
    systemd.services.tailscale-serve = lib.mkIf cfg.tailscaleServe {
      description = "Publish Caddy through tailscale serve";
      after = [
        "tailscaled.service"
        "caddy.service"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "30s";
        ExecStart = "${lib.getExe pkgs.tailscale} serve --bg --https=443 http://localhost:${toString cfg.listenPort}";
      };
    };

    services.caddy = {
      enable = true;

      # Terminated by tailscale serve, so Caddy speaks plain http on loopback
      # and must not try to get its own certificate.
      globalConfig = lib.mkIf (cfg.routing == "path") "auto_https off";

      virtualHosts =
        if cfg.routing == "path" then
          {
            ":${toString cfg.listenPort}".extraConfig = lib.concatStringsSep "\n" (
              lib.mapAttrsToList site cfg.sites
            );
          }
        else
          lib.mapAttrs' (
            name: s: lib.nameValuePair "${name}.${cfg.domain}" { extraConfig = site name s; }
          ) cfg.sites;
    };
  };
}
