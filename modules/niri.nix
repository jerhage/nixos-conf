{ config, lib, ... }:
let cfg = config.my.niri; in
{
  options.my.niri.enable = lib.mkEnableOption "niri Wayland session";

  config = lib.mkIf cfg.enable {
    programs.niri.enable = true;
    programs.xwayland.enable = true;

    services.displayManager.enable = true;
    services.displayManager.ly.enable = true;

    environment.variables = {
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      OZONE_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
    };

    assertions = [
      {
        assertion = config.services.displayManager.ly.enable;
        message = "my.niri needs a display manager; enable services.displayManager.ly on this host.";
      }
    ];
  };

  # NOTE: the shell components that run *inside* the session (bar, launcher,
  # lock screen, notification daemon) are intentionally NOT configured here.
  # They live in two places, so they can be swapped independently of the
  # compositor:
  #   - packages:      environment.systemPackages in the host file
  #   - user configs:  modules/home/{waybar,wofi}.nix and modules/home/niri/
}
