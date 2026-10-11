{ config, lib, pkgs, ... }:
let cfg = config.my.theming; in
{
  options.my.theming.enable = lib.mkEnableOption "dark Qt theme and cursor packages";

  # GTK settings live in ~/dotfiles/gtk, symlinked by my.dotfiles.links.
  # Only the packages and the options with no dotfile equivalent are here.
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      adwaita-icon-theme
      catppuccin-cursors.mochaSapphire
    ];

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        { settings."org/gnome/desktop/interface".color-scheme = "prefer-dark"; }
      ];
    };

    environment.sessionVariables = {
      XCURSOR_THEME = "catppuccin-mocha-sapphire-cursors";
      XCURSOR_SIZE = "16";
    };
  };
}
