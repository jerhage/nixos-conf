{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.mpv;
in
{
  options.my.mpv.enable = lib.mkEnableOption "mpv with scripts";

  # mpv reads ~/.config/mpv/mpv.conf natively, which my.dotfiles.links points
  # at ~/dotfiles/mpv. Only the package (with its scripts) belongs in Nix.
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.mpv.override {
        scripts = with pkgs.mpvScripts; [
          uosc
          sponsorblock
          mpvacious
        ];
      })
    ];
  };
}
