{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.niri;
in
{
  options.my.niri.enable = lib.mkEnableOption "niri Wayland session";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.xwayland-satellite
      (pkgs.callPackage ../pkgs/niri-keys { })
    ];

    programs.niri.enable = true;
    programs.xwayland.enable = true;

    environment.variables = {
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      OZONE_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
    };
  };

  # Compositor and session only; the shell running inside it is my.noctalia, so
  # the two can be swapped independently. programs.niri has no config option --
  # ~/.config/niri is symlinked to the dotfiles repo by my.dotfiles.links.
}
