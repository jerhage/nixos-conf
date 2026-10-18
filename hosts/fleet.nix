# The machines, and the few facts other machines need about them. Adding one is
# an entry here and nothing else: every host with an ssh server accepts the
# keys listed here, and generates a client alias for each of the others.
#
# lan      address on the LAN, the fallback when the tailnet is down
# tailnet  MagicDNS name, only when it differs from the alias
# userKey  public key this machine's user connects with
#
# Option types and the rest live in modules/fleet.nix. Nothing here is secret:
# these are public keys, and they are read at eval time, so sops cannot hold
# them without making ssh depend on decryption.
{
  nucleus = {
    lan = "10.10.1.202";
    userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgYJvoB7Z9QOIud/s1Zgho8Ssmp33uzXx8TX5DdCCQy nixos-desktop";
  };

  cortex = {
    lan = "10.10.1.5";
  };

  helix = {
    # Reserved on the homelab DHCP server, so it is stable enough to be the
    # fallback. Its ssh server still listens on the tailnet only.
    lan = "10.10.1.191";
    userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKfYPIQhcN04NPvOImoZBQ4XYjdyFLl5iIiCCeE98u2t jh@helix";
  };

  mbp = {
    lan = "10.10.1.115";
    tailnet = "jeremys-macbook-pro";
    userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKmSb03l6MOhGnJzit57QfPMBlashhIfzVRk/KXx49U personal-mb";
  };
}
