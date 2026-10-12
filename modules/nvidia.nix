{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.nvidia;
in
{
  options.my.nvidia.enable = lib.mkEnableOption "NVIDIA proprietary graphics";

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;
    hardware.nvidia = {
      modesetting.enable = true;
      open = false;
    };

    environment.systemPackages = with pkgs; [
      nvidia-vaapi-driver
      nvidia-modprobe
    ];

    services.xserver.videoDrivers = [ "nvidia" ];

    environment.variables = {
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    };
  };
}
