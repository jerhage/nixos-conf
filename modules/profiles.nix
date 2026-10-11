{ config, lib, ... }:
let cfg = config.my.profiles; in
{
  options.my.profiles = {
    workstation.enable = lib.mkEnableOption "graphical workstation bundle";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.workstation.enable {
      my.niri.enable = lib.mkDefault true;
      my.desktop.enable = lib.mkDefault true;
      my.audio.enable = lib.mkDefault true;
      my.bluetooth.enable = lib.mkDefault true;
      my.fonts.enable = lib.mkDefault true;
      my.i18n.enable = lib.mkDefault true;
      my.networking.enable = lib.mkDefault true;
      my.udev.enable = lib.mkDefault true;
    })
  ];
}
