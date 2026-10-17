{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.tailscale;
in
{
  options.my.tailscale = {
    enable = lib.mkEnableOption "Tailscale mesh VPN";

    tailnet = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "tail1a2b3c.ts.net";
      description = ''
        MagicDNS suffix of the tailnet, from `tailscale status --json | jq -r
        .MagicDNSSuffix`. Lets a config name another host on the tailnet without
        hardcoding the suffix at every use.
      '';
    };

    fqdn = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = lib.optionalString (cfg.tailnet != "") "${config.networking.hostName}.${cfg.tailnet}";
      description = "This host's MagicDNS name. Empty until `tailnet` is set.";
    };

    gui = lib.mkEnableOption ''
      trayscale, a GTK4 tray applet and window around the Tailscale CLI.
      Separate from `enable` so a headless host does not pull in GTK.

      Note the alternatives are decoys: the nixpkgs `tailscale-gui` package is
      the macOS client, and `tailscale-systray` has not been updated since 2022
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.gui { environment.systemPackages = [ pkgs.trayscale ]; })

    (lib.mkIf cfg.enable {
      services.tailscale = {
        enable = true;

        # Enough to reach other machines on the tailnet. "client" to use an exit
        # node or accept subnet routes, "server" to advertise them.
        useRoutingFeatures = "none";

        # UDP 41641 lets peers connect directly instead of relaying via DERP.
        openFirewall = true;

        # Without this the local API refuses non-root callers, so GUIs and
        # anything reading preferences get "Access denied".
        extraSetFlags = [ "--operator=${config.my.user}" ];
      };

    })
  ];
}
