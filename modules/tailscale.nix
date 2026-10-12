{ config, lib, pkgs, ... }:
let cfg = config.my.tailscale; in
{
  options.my.tailscale = {
    enable = lib.mkEnableOption "Tailscale mesh VPN";

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

        # "none" is correct for only reaching other machines on the tailnet.
        # Direct peer connections need no IP forwarding. Raise to "client" to
        # use an exit node or accept subnet routes advertised by peers,
        # "server" to be an exit node or advertise routes yourself.
        useRoutingFeatures = "none";

        # Opens UDP 41641 so peers can reach this host directly. Without it
        # connections still work, but fall back to relaying through a DERP
        # server, which is slower.
        openFirewall = true;

        # Lets my.user drive tailscaled without sudo. Without this the local
        # API refuses non-root callers, so `tailscale status` works but GUIs
        # and anything reading preferences get "Access denied".
        extraSetFlags = [ "--operator=${config.my.user}" ];
      };

      # Interaction with ProtonVPN, if both are running:
      #
      #   Routing is fine. Both use policy routing (ip rule + fwmark) rather
      #   than replacing the main table's default route, so they do not collide.
      #   Measured with the tunnel up: the tailnet peer stayed direct and ssh
      #   worked.

      #   DNS is fine without systemd-resolved. MagicDNS kept resolving with the
      #   tunnel up. Note that tailscaled answers MagicDNS even when offline, so
      #   resolution success is not evidence of reachability -- see the ssh
      #   Match block in the host. my.dns.systemdResolved stays off.
    })
  ];
}
