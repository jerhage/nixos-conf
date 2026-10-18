{ config, lib, ... }:
{
  options.my.profiles.workstation.enable =
    lib.mkEnableOption "graphical, on a machine that stays put";

  config = lib.mkIf config.my.profiles.workstation.enable {
    my.profiles.graphical.enable = lib.mkDefault true;

    # power-profiles-daemon persists the last choice, so this pins it.
    my.power.profile = lib.mkDefault "performance";
  };
}
