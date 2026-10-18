# The machines, and the few facts other machines need about them. Adding one is
# an entry here plus naming it in `my.ssh.server.authorize` on whichever hosts
# should accept its key.
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

  mbp = {
    lan = "10.10.1.115";
    tailnet = "jeremys-macbook-pro";
    userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKmSb03l6MOhGnJzit57QfPMBlashhIfzVRk/KXx49U personal-mb";
  };
}
