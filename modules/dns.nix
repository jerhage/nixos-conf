{ config, lib, ... }:
let
  cfg = config.my.dns;
in
{
  options.my.dns.systemdResolved = lib.mkEnableOption ''
    systemd-resolved as the DNS resolver, with NetworkManager handing DNS to it
    instead of writing /etc/resolv.conf itself
  '';

  # WHEN TO TURN THIS ON
  #
  # Leave it off while DNS behaves. Turn it on if name resolution starts failing
  # intermittently -- especially if MagicDNS (short tailnet names like
  # `jeremys-macbook-pro`) stops resolving after ProtonVPN connects, after a
  # network reconnect, or at random.
  #
  # The reason: without resolved, NetworkManager, Tailscale and ProtonVPN all
  # write /etc/resolv.conf through resolvconf and the last writer wins. Today
  # Tailscale happens to win, so MagicDNS works and the search path carries both
  # the tailnet domain and localdomain. That is a race that happens to be going
  # our way, not an arrangement.
  #
  # With resolved, Tailscale registers MagicDNS as a split-DNS route scoped to
  # the tailnet domain only, so global DNS can belong to NetworkManager or
  # ProtonVPN while *.ts.net still resolves. Deterministic instead of raced.
  #
  # Both settings below are needed. Enabling resolved without pointing
  # NetworkManager at it leaves a half-configured stack where resolved never
  # learns the upstream servers.
  config = lib.mkIf cfg.systemdResolved {
    services.resolved.enable = true;
    networking.networkmanager.dns = "systemd-resolved";
  };
}
