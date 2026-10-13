{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.gaming;
in
{
  options.my.gaming.enable = lib.mkEnableOption "Steam, gamemode and controller support";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;

      # Do NOT also list steam/steam-run in environment.systemPackages: this
      # module installs cfg.package, an override carrying fontPackages, and a
      # manual pkgs.steam shadows it with a build that has no fonts.
    };
    programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      lutris
      faugus-launcher
    ];

    boot.kernelModules = [
      "hid_playstation"
      "xpad"
    ];
  };
}
