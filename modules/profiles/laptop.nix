{ config, lib, ... }:
{
  options.my.profiles.laptop.enable =
    lib.mkEnableOption "graphical, on a machine that runs on battery";

  config = lib.mkIf config.my.profiles.laptop.enable {
    my.profiles.graphical.enable = lib.mkDefault true;

    my.power.profile = lib.mkDefault "power-saver";

    # Compresses rather than swapping to disk, which matters more where there
    # is less RAM than the desktop has.
    my.zram.enable = lib.mkDefault true;
  };
}
