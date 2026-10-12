{ config, lib, ... }:
let
  cfg = config.my.networking;
in
{
  options.my.networking.enable = lib.mkEnableOption "NetworkManager-based networking";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
