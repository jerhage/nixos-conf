{ config, lib, ... }:
let cfg = config.my.zram; in
{
  options.my.zram.enable = lib.mkEnableOption "zram compressed swap";

  config = lib.mkIf cfg.enable {
    # compresses ram instead of using disk for swap. Especially nice for weaker machines
    zramSwap = {
      enable = true;
      priority = 100;
      algorithm = "lz4"; # one of many algorithms
      memoryPercent = 50; # will compress upto 50% of available memory when needed (after ram is full)
    };
  };
}
