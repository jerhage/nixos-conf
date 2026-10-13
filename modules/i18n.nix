{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.i18n;

  languageSets = {
    korean = {
      locale = "ko_KR.UTF-8/UTF-8";
      addons = [ pkgs.fcitx5-hangul ];
    };
    japanese = {
      locale = "ja_JP.UTF-8/UTF-8";
      addons = [ pkgs.fcitx5-mozc ];
    };
  };

  selected = map (name: languageSets.${name}) cfg.languages;
in
{
  options.my.i18n = {
    enable = lib.mkEnableOption "locales and the fcitx5 input method";

    languages = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (builtins.attrNames languageSets));
      default = [ ];
      example = [
        "korean"
        "japanese"
      ];
      description = ''
        Input languages beyond English. Each adds its locale and its fcitx5
        engine, so the two cannot drift apart.

        Installing an engine does not activate it: add it in fcitx5-configtool
        (Mozc, Hangul -- not the "Keyboard - <lang>" layouts), which writes
        ~/.config/fcitx5/profile per user.

        Fonts are deliberately not tied to this: noto-fonts-cjk-sans in
        my.fonts already covers every CJK language.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kdePackages.fcitx5-configtool ];

    i18n.defaultLocale = "en_US.UTF-8";
    i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ] ++ map (l: l.locale) selected;

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;
        addons = [
          pkgs.fcitx5-gtk
          pkgs.kdePackages.fcitx5-qt
          pkgs.kdePackages.fcitx5-configtool
        ]
        ++ lib.concatMap (l: l.addons) selected;
      };
    };

    # No IM env vars here: waylandFrontend sets XMODIFIERS and deliberately
    # omits GTK_IM_MODULE/QT_IM_MODULE so Wayland apps use text-input-v3.
  };
}
