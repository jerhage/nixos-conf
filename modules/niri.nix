{ config, lib, pkgs, ... }:
let cfg = config.my.niri; in
{
  options.my.niri.enable = lib.mkEnableOption "niri Wayland session";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xwayland
      xwayland-satellite
    ];

    programs.niri.enable = true;
    programs.xwayland.enable = true;

    environment.variables = {
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      OZONE_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
    };
  };

  # NOTE: this module covers the compositor and session only. The shell that
  # runs *inside* it (bar, launcher, lock screen, notifications) is a separate
  # module, so the two can be swapped independently. The niri config itself is
  # not managed here at all: programs.niri has no config option, and
  # ~/.config/niri is symlinked to the dotfiles repo by my.dotfiles.links.
}
