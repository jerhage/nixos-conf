{ config, lib, ... }:
let cfg = config.my.virtualisation; in
{
  options.my.virtualisation.enable = lib.mkEnableOption "libvirtd and podman containers";

  config = lib.mkIf cfg.enable {
    # enable containerization ( podman )
    programs.virt-manager.enable = true;
    virtualisation.containers.enable = true;
    virtualisation = {
      libvirtd = {
        enable = true;
      };
      podman = {
        enable = true;

        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
