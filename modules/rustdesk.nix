{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.rustdesk;
in
{
  # Its own module rather than a line in my.apps: being reachable needs a
  # firewall port, and the port and the package should not drift apart.
  options.my.rustdesk = {
    enable = lib.mkEnableOption "RustDesk, reachable over the tailnet";

    port = lib.mkOption {
      type = lib.types.port;
      default = 21118;
      description = ''
        Port for direct IP access, the one RustDesk's security settings
        suggest. Opening it is not enough: direct IP access also has to be
        ticked in the app, which is what decides whether anything listens.
      '';
    };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "tailscale0" ];
      description = ''
        Interfaces that accept connections. Tailnet only by default, so a
        laptop does not answer on whatever network it has joined. Tailscale
        routes the traffic but does not exempt it from the firewall.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rustdesk ];

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ cfg.port ];
    });
  };
}
