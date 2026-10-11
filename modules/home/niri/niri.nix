{ config, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
in
{
  xdg.configFile."niri" = {
    source = create_symlink "${dotfiles}/niri/.config/niri/";
    recursive = true;
  };
  # xdg.configFile."nvim" = {
  #   source = create_symlink "${dotfiles}/nvim/.config/nvim/";
  #   recursive = true;
  # };
  xdg.configFile."swaylock/config".source = ./mocha.conf;
  home.file.".local/bin/nws.sh".source = ./nws.sh;

}
