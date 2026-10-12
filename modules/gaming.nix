{ config, lib, pkgs, ... }:
let cfg = config.my.gaming; in
{
  options.my.gaming.enable = lib.mkEnableOption "Steam, gamemode and controller support";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;

    };
    programs.gamemode.enable = true;

    boot.kernelModules = [
      "hid_playstation"
      "xpad"
    ];
  };
}
