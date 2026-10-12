{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.fonts;
in
{
  options.my.fonts.enable = lib.mkEnableOption "shared font set";

  config = lib.mkIf cfg.enable {
    fonts = {
      fontconfig.enable = true;

      # Without this, fc-match for sans/serif/monospace at lang=ko returns
      # DejaVu, which has no Korean glyphs -- Korean text renders as boxes.
      # Installing the CJK fonts is not enough; they must be named as fallbacks.
      fontconfig.defaultFonts = {
        sansSerif = [
          "Noto Sans"
          "Noto Sans CJK KR"
        ];
        serif = [
          "Noto Serif"
          "Noto Sans CJK KR"
        ];
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Sans Mono CJK KR"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        nerd-fonts.jetbrains-mono
      ];
    };
  };
}
