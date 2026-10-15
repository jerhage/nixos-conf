{ config, lib, ... }:
let
  cfg = config.my.vm;
in
{
  options.my.vm.graphics = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Open a QEMU window instead of running on the console. Off by default:
      a host driving a real GPU rarely boots graphically under emulation.
    '';
  };

  # Applies only to `nixos-rebuild build-vm`.
  config.virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      diskSize = 8192;

      # Console in the terminal; exit with `poweroff`.
      inherit (cfg) graphics;
    };

    users.users.${config.my.user}.initialPassword = "nixos";
  };
}
