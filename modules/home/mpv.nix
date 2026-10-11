{ config, pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc
      sponsorblock
      mpvacious
    ];
    # package = (
    #   pkgs.mpv-unwrapped.override {
    #     scripts = with pkgs.mpvScripts; [
    #       uosc
    #       sponsorblock
    #       mpvacious
    #     ];
    #
    #     waylandSupport = true;
    #     # mpv = pkgs.mpv-unwrapped.override {
    #     #   waylandSupport = true;
    #     # };
    #   }
    # );

    config = {
      profile = "high-quality";
      ytdl-format = "bestvideo+bestaudio";
      cache-default = 4000000;
    };
  };
}
