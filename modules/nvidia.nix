{ config, lib, ... }:
let cfg = config.my.nvidia; in
{
  options.my.nvidia.enable = lib.mkEnableOption "NVIDIA proprietary graphics";

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;
    hardware.nvidia = {
      modesetting.enable = true;
      open = false;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    environment.variables = {
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    };
  };
}
