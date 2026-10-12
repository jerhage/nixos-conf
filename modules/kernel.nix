{ config, lib, pkgs, ... }:
let
  cfg = config.my.kernel;

  branches = {
    default = pkgs.linuxPackages;
    latest = pkgs.linuxPackages_latest;
    zen = pkgs.linuxPackages_zen;
    xanmod = pkgs.linuxPackages_xanmod;
    lts_6_12 = pkgs.linuxPackages_6_12;
  };
in
{
  options.my.kernel.branch = lib.mkOption {
    type = lib.types.enum (builtins.attrNames branches);
    default = "default";
    description = ''
      Which kernel branch to boot. These select a branch, not a point release.

      - `default`: nixpkgs default, conservative branch (6.18.x). Also what
        NixOS uses when unset. Receives security and bug backports
        indefinitely, but not new hardware enablement.
      - `latest`: newest mainline branch (7.2.x). New hardware support lands
        here first; the proprietary nvidia driver may not build against it.
      - `zen`, `xanmod`: patched variants, desktop-latency oriented.
      - `lts_6_12`: pinned to 6.12.x. Pinned branches are dropped from nixpkgs
        once end-of-life, so a pin eventually fails to evaluate.
    '';
  };

  # mkDefault so a host can still set boot.kernelPackages directly for a branch
  # that is not in the enum, without colliding with this module.
  config.boot.kernelPackages = lib.mkDefault branches.${cfg.branch};
}
