{ config, lib, ... }:
{
  options.my.profiles.graphical.enable = lib.mkEnableOption ''
    the graphical session and desktop applications. Says nothing about power
    or whose machine it is
  '';

  config = lib.mkIf config.my.profiles.graphical.enable {
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
    my.apps.enable = lib.mkDefault true;
    my.mpv.enable = lib.mkDefault true;
    my.rustdesk.enable = lib.mkDefault true;
    my.terminals.enable = lib.mkDefault true;

    # Typing CJK needs a graphical session; base only sets locales.
    my.i18n.inputMethod.enable = lib.mkDefault true;

    my.greeter.backend = lib.mkDefault "ly";
  };
}
