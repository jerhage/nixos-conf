{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.bluetooth;
in
{
  options.my.bluetooth.enable = lib.mkEnableOption "Bluetooth with blueman";

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          AutoEnable = true;
          ControllerMode = "dual";
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

    # blueman's XDG autostart entry puts a tray icon next to noctalia's own
    # bluetooth widget. Masked, so blueman-manager stays usable for pairing.
    systemd.user.units."app-blueman@autostart.service".enable = false;

    # Xbox One/Series pads will not pair over Bluetooth with Enhanced
    # Retransmission Mode on. Needed only for those.
    boot.extraModprobeConfig = ''
      options bluetooth disable_ertm=1
    '';
  };
}
