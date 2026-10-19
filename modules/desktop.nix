{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.desktop;
in
{
  options.my.desktop.enable = lib.mkEnableOption "desktop portals, polkit and gvfs";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      glib # gsettings, used by portals and GTK apps
      nautilus
      polkit
      wl-clipboard-rs
    ];

    # Backends belong here, not in systemPackages: the portal service only
    # looks at extraPortals, and a package listed in both can shadow it.
    #
    # ScreenCast goes to gnome because that is the one niri implements, via
    # the Mutter API. xdg-desktop-portal-wlr captures through wlr-screencopy,
    # which niri does not provide, so screen sharing fails with a misleading
    # "wayland requires a higher version of linux distro".
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      config.common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
    };
    security.polkit.enable = true;
    services.gvfs.enable = true; # enables trash for file explorer
  };
}
