{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  my.user = "jh";

  # Headless: locales but no input method, no desktop.
  my.profiles.base.enable = true;
  my.i18n.languages = [
    "korean"
    "japanese"
  ];

  my.tailscale.enable = true;

  # Tailnet only. The LAN interface is deliberately absent.
  my.ssh.server.enable = true;

  my.secrets.enable = false;

  # Until the dotfiles repo is provisioned here, the links would dangle.
  my.dotfiles.enable = false;

  my.server.enable = true;
  my.server.sites.books.port = 8083;
  my.server.sites.anki.port = 8080;

  # Clients point at https://<host>/anki/ -- the trailing slash matters.
  # No app-side prefix config: it serves an API and generates no links.
  my.ankiSync.enable = true;

  services.calibre-web = {
    enable = true;
    listen.ip = "127.0.0.1";
    listen.port = 8083;
    options = {
      enableBookUploading = true;
      enableBookConversion = true;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "26.05";
}
