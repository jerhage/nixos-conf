{ config, lib, pkgs, ... }:
let cfg = config.my.fonts; in
{
  options.my.fonts.enable = lib.mkEnableOption "shared font set";

  config = lib.mkIf cfg.enable {
    fonts = {
      fontconfig.enable = true;
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
