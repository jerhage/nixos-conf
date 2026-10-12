{ config, lib, pkgs, ... }:
let
  cfg = config.my.niri;
  # Window switcher, bound to Mod+Shift+TAB in the niri config.
  # Was ~/.local/bin/nws.sh under home-manager; now a real binary on PATH.
  nws = pkgs.writeShellApplication {
    name = "nws";
    runtimeInputs = with pkgs; [
      niri
      jq
      wofi
    ];
    text = builtins.readFile ./nws.sh;
  };
in
{
  options.my.niri.enable = lib.mkEnableOption "niri Wayland session";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ nws ];

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

  # NOTE: this module covers the compositor and session only. The shell that
  # runs *inside* it (bar, launcher, lock screen, notifications) is a separate
  # module, so the two can be swapped independently. The niri config itself is
  # not managed here at all: programs.niri has no config option, and
  # ~/.config/niri is symlinked to the dotfiles repo by my.dotfiles.links.
}
