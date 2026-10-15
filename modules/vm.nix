{ config, lib, ... }:
let
  cfg = config.my.vm;
in
{
  options.my.vm = {
    graphics = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open a QEMU window instead of running on the console. Off by default:
        a host driving a real GPU rarely boots graphically under emulation.
      '';
    };

    shareDotfiles = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Mount the host's dotfiles repo into the guest over 9p, so the links
        resolve to the same files the host edits. Off by default, which
        disables the links instead: without the repo they all dangle.
      '';
    };
  };

  # Applies only to `nixos-rebuild build-vm`.
  config.virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      diskSize = 8192;

      # Console in the terminal; exit with `poweroff`.
      inherit (cfg) graphics;

      sharedDirectories = lib.mkIf cfg.shareDotfiles {
        dotfiles = {
          source = config.my.dotfiles.path;
          target = config.my.dotfiles.path;
        };
      };
    };

    my.dotfiles.enable = lib.mkIf (!cfg.shareDotfiles) (lib.mkForce false);

    users.users.${config.my.user}.initialPassword = "nixos";
  };
}
