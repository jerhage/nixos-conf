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

      # Open kernel module; userspace stays proprietary. Turing and later.
      open = true;

      # Saves and restores VRAM around suspend.
      powerManagement.enable = true;
    };

    environment.systemPackages = with pkgs; [
      nvidia-modprobe
      libva-utils # vainfo
    ];

    services.xserver.videoDrivers = [ "nvidia" ];

    environment.variables = {
      LIBVA_DRIVER_NAME = "nvidia";

      # Firefox's RDD sandbox blocks the nvidia device nodes. Hardware decode
      # also needs about:config prefs set per host; see the driver README.
      MOZ_DISABLE_RDD_SANDBOX = "1";

      # Stops CUDA force-boosting clocks while decoding.
      CUDA_DISABLE_PERF_BOOST = "1";
    };
  };
}
