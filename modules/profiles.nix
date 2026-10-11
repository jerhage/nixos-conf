{ config, lib, ... }:
let cfg = config.my.profiles; in
{
  options.my.profiles = {
    workstation.enable = lib.mkEnableOption "graphical workstation bundle";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.workstation.enable {
      # session
      my.niri.enable = lib.mkDefault true;
      my.desktop.enable = lib.mkDefault true;
      my.theming.enable = lib.mkDefault true;
      my.awww.enable = lib.mkDefault true;

      # hardware / system
      my.audio.enable = lib.mkDefault true;
      my.bluetooth.enable = lib.mkDefault true;
      my.fonts.enable = lib.mkDefault true;
      my.networking.enable = lib.mkDefault true;
      my.udev.enable = lib.mkDefault true;
      my.i18n.enable = lib.mkDefault true;

      # interactive user environment
      # (would move to a `base` profile once a non-graphical host exists)
      my.shell.enable = lib.mkDefault true;
      my.ssh.enable = lib.mkDefault true;
      my.dotfiles.enable = lib.mkDefault true;
      my.mpv.enable = lib.mkDefault true;
    })
  ];
}
