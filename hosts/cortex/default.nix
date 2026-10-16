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

  my.secrets.enable = true;

  # Until the dotfiles repo is provisioned here, the links would dangle.
  my.dotfiles.enable = false;

  # Encrypted copy in Dropbox using rclone crypt
  my.sync.cloud.calibre-cloud = {
    local = "/var/lib/calibre/";
    remote = "crypt:calibre/";
    extraFlags = [
      "--exclude"
      ".DS_Store"
    ];
  };

  my.backup.enable = true;
  my.backup.paths = [
    "/var/lib/calibre"
    "/var/lib/calibre-web" # users, shelves, reading state
    "/var/lib/anki-sync-server" # collections exist nowhere else
  ];

  my.server.enable = true;
  my.server.tailscaleServe = true;
  my.server.sites.books.port = 8083;
  my.server.sites.anki.port = 8080;

  # Clients point at https://<host>/anki/ -- the trailing slash matters.
  # No app-side prefix config: it serves an API and generates no links.
  my.ankiSync.enable = true;

  # get_download_link passes force_unidecode=True, which bypasses the
  # "convert non-English characters" setting and romanises every download.
  # It then sends the result as filename*=UTF-8'' anyway, which is the header
  # built to carry the original. replace-fail so a version bump that moves this
  # line breaks the build rather than silently reverting.
  services.calibre-web.package = pkgs.calibre-web.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/calibreweb/cps/helper.py \
        --replace-fail 'replace_whitespace=False, force_unidecode=True' \
                       'replace_whitespace=False, force_unidecode=False'
    '';
  });

  services.calibre-web = {
    enable = true;
    listen.ip = "127.0.0.1";
    listen.port = 8083;
    options = {
      calibreLibrary = "/var/lib/calibre";
      enableBookUploading = true;
      enableBookConversion = true;
    };
  };

  # The nixos module already hardens this well; these are what it leaves out.
  # Not setting IPAddressDeny: calibre-web fetches metadata from the internet.
  # jh runs desktop calibre over ssh -X against the same library.
  users.users.jh.extraGroups = [ "calibre-web" ];

  # setgid so anything either of them creates stays group-writable.
  # The library arrives from rclone as 0644/0755, so the group can read it but
  # calibre-web cannot write metadata.db. An ACL rather than a mode: capital X
  # grants traversal on directories without marking every book executable, and
  # the d: entry makes new files inherit it.
  systemd.tmpfiles.rules = [
    "d /var/lib/calibre 2770 jh calibre-web -"
    "Z /var/lib/calibre - jh calibre-web -"
    "A+ /var/lib/calibre - - - - g:calibre-web:rwX,d:g:calibre-web:rwX"
  ];

  systemd.services.calibre-web.serviceConfig = {
    PrivateUsers = true;
    # 0007 not 0077: jh must read what calibre-web writes.
    UMask = "0007";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "26.05";
}
