{ config, lib, ... }:
let cfg = config.my.desktop; in
{
  options.my.desktop.enable = lib.mkEnableOption "desktop portals, polkit and gvfs";

  config = lib.mkIf cfg.enable {
    xdg.portal.wlr.enable = true;
    security.polkit.enable = true;
    services.gvfs.enable = true; # enables trash for file explorer
  };
}
