{ config, lib, ... }:
let
  cfg = config.my.dns;
in
{
  options.my.dns.systemdResolved = lib.mkEnableOption ''
    systemd-resolved as the DNS resolver, with NetworkManager handing DNS to it
    instead of writing /etc/resolv.conf itself
  '';

  # Without resolved, NetworkManager, Tailscale and any VPN all write
  # /etc/resolv.conf through resolvconf and the last writer wins. With it,
  # Tailscale registers MagicDNS as split-DNS scoped to the tailnet domain and
  # global DNS stays with NetworkManager. Both settings are needed: resolved
  # alone never learns the upstream servers.
  config = lib.mkIf cfg.systemdResolved {
    services.resolved.enable = true;
    networking.networkmanager.dns = "systemd-resolved";
  };
}
