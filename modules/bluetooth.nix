{ config, lib, pkgs, ... }:
let cfg = config.my.bluetooth; in
{
  options.my.bluetooth.enable = lib.mkEnableOption "Bluetooth with blueman";

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      package = pkgs.bluez;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          AutoEnable = true;
          ControllerMode = "bredr";
          UserspaceHID = true;
          Experimental = true;
          FastConnectable = true;
        };
        Input = {
          ClassicBondedOnly = false;
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };

    services.blueman.enable = true;

    boot.extraModprobeConfig = ''
      options bluetooth disable_ertm=1
    '';
  };
}
