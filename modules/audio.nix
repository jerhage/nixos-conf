{ config, lib, pkgs, ... }:
let cfg = config.my.audio; in
{
  options.my.audio.enable = lib.mkEnableOption "PipeWire audio stack";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.pavucontrol ];

    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
    };
  };
}
