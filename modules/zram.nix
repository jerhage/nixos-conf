{ config, lib, ... }:
let
  cfg = config.my.zram;
in
{
  options.my.zram.enable = lib.mkEnableOption "zram compressed swap";

  config = lib.mkIf cfg.enable {
    # compresses ram instead of using disk for swap. Especially nice for weaker machines
    zramSwap = {
      enable = true;
      priority = 100;
      algorithm = "zstd"; # better ratio than lz4 at similar speed
      memoryPercent = 50; # will compress upto 50% of available memory when needed (after ram is full)
    };
  };
}
