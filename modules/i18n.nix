{ config, lib, pkgs, ... }:
let cfg = config.my.i18n; in
{
  options.my.i18n.enable = lib.mkEnableOption "locales and the fcitx5 input method";

  config = lib.mkIf cfg.enable {
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "ko_KR.UTF-8/UTF-8"
    "ja_JP.UTF-8/UTF-8"
  ];
  # Enable IME
  # i18n.inputMethod = {
  #   enable = true;
  #   type = "kime";
  # kime.iconColor = "White";
  # fcitx5.addons = with pkgs; [
  #   fcitx5-mozc
  #   fcitx5-hangul
  #   fcitx5-gtk
  # ];
  # };
i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-hangul
        fcitx5-gtk
        kdePackages.fcitx5-qt
        kdePackages.fcitx5-configtool
      ];
    };
  };

  # No IM env vars here on purpose. With waylandFrontend = true the fcitx5
  # module sets XMODIFIERS (for XWayland) and deliberately omits
  # GTK_IM_MODULE/QT_IM_MODULE so Wayland apps use text-input-v3 instead of
  # the legacy IM-module path. Setting them back breaks that.
  };
}
