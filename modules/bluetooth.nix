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

    environment.systemPackages = [ pkgs.bluez ];

    services.blueman.enable = true;

    # blueman ships an XDG autostart entry, which systemd turns into
    # app-blueman@autostart.service and puts a tray icon next to noctalia's
    # own bluetooth widget. Mask it: blueman-manager stays available for
    # pairing, but nothing autostarts into the tray.
    systemd.user.units."app-blueman@autostart.service".enable = false;

    boot.extraModprobeConfig = ''
      options bluetooth disable_ertm=1
    '';
  };
}
