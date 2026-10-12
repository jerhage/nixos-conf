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
      xdg-desktop-portal
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];

    xdg.portal.wlr.enable = true;
    security.polkit.enable = true;
    services.gvfs.enable = true; # enables trash for file explorer
  };
}
