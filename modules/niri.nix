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
  # Compositor only; the shell inside it is my.noctalia. programs.niri has no
  # config option -- ~/.config/niri is symlinked by my.dotfiles.links.
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
}
