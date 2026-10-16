{ pkgs, ... }:
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


  # eno1 keeps ssh reachable on the LAN; without it a switch before tailscale
  # is up locks you out.
  my.ssh.server.interfaces = [
    "eno1"
    "tailscale0"
  ];

  users.users.jh.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgYJvoB7Z9QOIud/s1Zgho8Ssmp33uzXx8TX5DdCCQy nixos-desktop"
  ];

  my.ssh.server.enable = true;

  # Bulk metadata editing means running desktop calibre here over ssh -X.
  services.openssh.settings.X11Forwarding = true;
  environment.systemPackages = [ pkgs.calibre ];

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

  # The nixos module already hardens this well; these are what it leaves out.
  # Not setting IPAddressDeny: calibre-web fetches metadata from the internet.
  systemd.services.calibre-web.serviceConfig = {
    PrivateUsers = true;
    UMask = "0077";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "26.05";
}
