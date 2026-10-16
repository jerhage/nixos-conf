{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  my.user = "jh";
  my.profiles.workstation.enable = true;

  # machine-specific capabilities
  my.nvidia.enable = true;
  my.zram.enable = true;
  my.gaming.enable = true;
  my.virtualisation.enable = true;
  my.onepassword.enable = true;
  my.ssh.server.enable = true;
  my.ssh.server.interfaces = [
    "eno1"
    "tailscale0"
  ];
  my.devtools.enable = true;
  my.secrets.enable = true;
  my.devtools.agentSandbox = true;
  my.devtools.languages = [
    "c"
    "deno"
    "elixir"
    "go"
    "nix"
    "node"
    "rust"
  ];
  my.i18n.languages = [
    "korean"
    "japanese"
  ];
  my.tailscale.enable = true;
  my.tailscale.gui = true;

  my.shell.history = "fzf";

  # Without this, Tailscale owned /etc/resolv.conf alone and DNS failed at
  # login until the link was toggled -- see modules/dns.nix.
  my.dns.systemdResolved = true;
  my.greeter.backend = "noctalia";

  # Desktop on mains power: no reason to throttle.
  my.power.profile = "performance";

  # Firmware updates for LVFS-supported devices. Not this board's BIOS.
  services.fwupd.enable = true;

  # This board's S3 never resumes; s2idle avoids the firmware handoff.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    # Bounds the boot menu. Older generations stay in /nix until collected.
    systemd-boot.configurationLimit = 10;
  };

  hardware.enableAllFirmware = true;

  time.timeZone = "America/Chicago";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Live symlinks into the self-managed dotfiles repo. Edits there take
  # effect without a rebuild.
  my.dotfiles = {
    links = {
      # shell
      ".bashrc" = "bash/.bashrc";
      ".profile" = "bash/.profile";

      # app configs
      ".config/mpv/mpv.conf" = "mpv/.config/mpv/mpv.conf";
      ".config/niri" = "niri/.config/niri";
      ".config/noctalia" = "noctalia/.config/noctalia";
      # Noctalia writes GUI/msg changes here, and this file loads AFTER
      # ~/.config/noctalia, so it wins. Linked so styling is tracked.
      ".local/state/noctalia/settings.toml" = "noctalia/.local/state/noctalia/settings.toml";
      ".config/gtk-3.0/settings.ini" = "gtk/.config/gtk-3.0/settings.ini";
      ".config/gtk-4.0/settings.ini" = "gtk/.config/gtk-4.0/settings.ini";
      ".gtkrc-2.0" = "gtk/.gtkrc-2.0";

      # migrated off stow
      ".config/ghostty" = "ghostty/.config/ghostty";
      # Individual files, not the directory: conf/cached_layouts is a
      # regenerated cache, and fcitx5 writes these on GUI changes.
      ".config/fcitx5/profile" = "fcitx5/.config/fcitx5/profile";
      ".config/fcitx5/config" = "fcitx5/.config/fcitx5/config";
      ".config/fcitx5/conf/hangul.conf" = "fcitx5/.config/fcitx5/conf/hangul.conf";
      ".config/fcitx5/conf/keyboard.conf" = "fcitx5/.config/fcitx5/conf/keyboard.conf";
      ".config/fcitx5/conf/notifications.conf" = "fcitx5/.config/fcitx5/conf/notifications.conf";
      ".config/nono/profiles" = "nono/.config/nono/profiles";
      ".config/nvim" = "nvim/.config/nvim";
      ".config/starship" = "starship/.config/starship";
      ".config/starship.toml" = "starship/.config/starship.toml";
      ".config/tmux" = "tmux/.config/tmux";
      ".config/wezterm" = "wezterm/.config/wezterm";
      ".config/yazi" = "yazi/.config/yazi";
    };
  };
  my.vm.shareDotfiles = false;

  my.sync.pulls.pictures = {
    from = "mbp:~/Pictures/";
    to = "~/Pictures/";
  };

  my.sync.cloud = {
    tmw = {
      local = "~/tmw/";
      remote = "crypt:tmw/";
    };
  };

  # Host aliases live here rather than ~/.ssh/config so they stay per-host Nix
  # config. modules/ssh.nix adds a "Host *" block above this one.
  programs.ssh.extraConfig = ''
    # Prefer the tailnet, fall back to the LAN. Probes TCP rather than
    # resolving, because tailscaled answers MagicDNS while offline.
    Match host mbp exec "timeout 2 bash -c 'exec 3<>/dev/tcp/jeremys-macbook-pro/22' 2>/dev/null"
      HostName jeremys-macbook-pro

    Host mbp
      HostName 10.10.1.115
      User jh
      IdentityFile ~/.ssh/id_ed25519_nix
      IdentitiesOnly yes
      HostKeyAlias mbp

    Host cortex
      HostName 10.10.1.5
      User jh
      IdentityFile ~/.ssh/id_ed25519_nix
      IdentitiesOnly yes
      HostKeyAlias cortex
  '';

  users.users.${config.my.user} = {
    description = "Main User";
    extraGroups = [
      "networkmanager"
      "wireshark"
    ];

    packages = with pkgs; [
      # chromium
      google-chrome
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKmSb03l6MOhGnJzit57QfPMBlashhIfzVRk/KXx49U personal-mb"
    ];
  };

  environment.systemPackages = with pkgs; [
    # cli / system
    ffmpeg
    # stow # not using atm in favor of custom dotfiles module
    usbutils # lsusb, usb-devices
    wev # wayland event viewer

    # dev
    lazygit
    tree-sitter

    # network / security
    nmap
    openvpn
    proton-vpn
    proton-pass
    rclone

    # desktop applications
    anki
    # calibre # using calibre-web via @cortex now
    cryptomator
    discord
    dropbox
    gcolor3
    ghostty
    imv
    kdePackages.kate
    obs-studio
    obsidian
    playerctl
    qbittorrent
    spotify
    wezterm
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight

    # accounting
    beancount
    fava

    claude-code

    (pkgs.callPackage ../../pkgs/nvim-desktop-item { })

    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      excludeShellChecks = [ "SC2016" ];
      text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
    })
  ];

  # Otherwise whatever registered last wins; calibre was claiming text/plain.
  xdg.mime.defaultApplications = {
    "text/plain" = "nvim-ghostty.desktop";
    "text/markdown" = "nvim-ghostty.desktop";
    "text/csv" = "nvim-ghostty.desktop";
    "application/json" = "nvim-ghostty.desktop";
    "application/x-shellscript" = "nvim-ghostty.desktop";
  };

  system.stateVersion = "25.11";
}
