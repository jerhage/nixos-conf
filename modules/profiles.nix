{ config, lib, ... }:
let
  cfg = config.my.profiles;
in
{
  options.my.profiles = {
    base.enable = lib.mkEnableOption "interactive user environment, no graphics";
    workstation.enable = lib.mkEnableOption "graphical workstation bundle";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.base.enable {
      my.cli.enable = lib.mkDefault true;
      my.shell.enable = lib.mkDefault true;
      my.ssh.agent.enable = lib.mkDefault true;
      my.dotfiles.enable = lib.mkDefault true;
      my.networking.enable = lib.mkDefault true;
      my.i18n.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.workstation.enable {
      my.profiles.base.enable = lib.mkDefault true;

      # session
      my.niri.enable = lib.mkDefault true;
      my.noctalia.enable = lib.mkDefault true;
      my.desktop.enable = lib.mkDefault true;
      my.theming.enable = lib.mkDefault true;

      # hardware / system
      my.audio.enable = lib.mkDefault true;
      my.bluetooth.enable = lib.mkDefault true;
      my.fonts.enable = lib.mkDefault true;
      my.keyboard.enable = lib.mkDefault true;
      my.power.enable = lib.mkDefault true;

      # desktop applications
      my.mpv.enable = lib.mkDefault true;

      # Typing CJK needs a graphical session; base only sets locales.
      my.i18n.inputMethod.enable = lib.mkDefault true;
    })
  ];
}
