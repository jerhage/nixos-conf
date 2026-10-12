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
  my.openssh.enable = true;

  # Desktop on mains power: no reason to throttle.
  my.power.profile = "performance";

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
  };

  my.kernel.branch = "default";

  hardware.enableAllFirmware = true;

  networking = {
    hosts = {
      # "192.168.18.33" = [ "raspi.casa.local" ];
      # "10.129.182.29" = [
      # "blog.inlanefreight.local"
      # "blog-dev.inlanefreight.local"
      # ];
    };
  };

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
    };
  };

  # Host aliases live here rather than ~/.ssh/config: this machine has a single
  # user, and routing them through Nix makes them configurable per host.
  # modules/ssh.nix contributes a "Host *" block that lands above this one. That
  # only matters if both set the same option -- ssh takes the first value it
  # finds per option. Verify with `ssh -G mbp` after changing either.
  programs.ssh.extraConfig = ''
    Host mbp
      HostName 10.10.1.115
      User jh
      IdentityFile ~/.ssh/id_ed25519_nix
      IdentitiesOnly yes
  '';

  programs.nix-ld.enable = true;
  programs.wireshark.enable = true;

  users.users.${config.my.user} = {
    description = "Main User";
    extraGroups = [
      "networkmanager"
      "wireshark"
      "docker"
      "plugdev" # zsa moonlander udev
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
    kdePackages.fcitx5-configtool

    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight
    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      excludeShellChecks = [ "SC2016" ];
      text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
    })
    ffmpeg
    jq
    ripgrep
    fzf
    fd
    fastfetch
    btop
    starship
    playerctl
    nvidia-vaapi-driver
    nvidia-modprobe
    neovim
    wget
    wl-clipboard-rs
    git
    glib
    curl
    discord
    obs-studio
    spotify
    # lsd
    bat
    tmux
    fzf
    lazygit
    lazydocker
    ghostty
    adw-gtk3
    papirus-icon-theme
    nh
    nautilus
    gnumake
    go
    gopls
    cargo
    #musl
    gcc
    #ly
    fastfetch
    btop
    pavucontrol
    # bitwarden-desktop
    docker
    docker-compose
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    xdg-desktop-portal
    polkit
    nixfmt-rfc-style
    obsidian
    nmap
    openvpn
    #hashcat
    #burpsuite
    #caido
    wireshark
    kdePackages.kate
    tree-sitter

    anki
    #wordlists
    #rockyou
    #seclists
    #metasploit
    #gobuster
    #ffuf
    #sqlmap
    #john
    #thc-hydra
    qbittorrent
    stow
    yazi
    wezterm
    # TODO: how to replace this. Need for stylua to install...
    unzip
    usbutils # lsusb, usb-devices
    #blueman
    bluez
    proton-vpn
    #grub2
    xwayland
    xwayland-satellite
    nodejs_24
    typescript
    pnpm
    wev # wayland event viewer

    pv
    zstd
    dropbox
    rclone
    cryptomator
    calibre
    calibre-web
    # containers
    podman
    podman-compose
    podman-desktop
    # kime
    adwaita-icon-theme # for fcitx icon?

    beancount
    fava

    dysk
    gcolor3
    # like lutris but easier?
    faugus-launcher
    claude-code
    lutris
  ];

  # systemd.services.toggle-gpp-on-suspend = {
  #   description = "Toggle GPP wake pins around suspend to prevent fan/spurious wake issues";
  #   wantedBy = [ "sleep.target" ];
  #   before = [ "sleep.target" ];
  #
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = ''
  #       # Runs BEFORE suspend: disable wake pins
  #       ${pkgs.bash}/bin/bash -c 'echo GPP0 > /proc/acpi/wakeup'
  #       ${pkgs.bash}/bin/bash -c 'echo GPP8 > /proc/acpi/wakeup'
  #     '';
  #     ExecStop = ''
  #       # Runs AFTER resume: restore wake pins
  #       ${pkgs.bash}/bin/bash -c 'echo GPP0 > /proc/acpi/wakeup'
  #       ${pkgs.bash}/bin/bash -c 'echo GPP8 > /proc/acpi/wakeup'
  #     '';
  #   };
  # };
  # systemd.services.disable-acpi-wakeup = {
  #   description = "Disable ACPI wakeup on user login";
  #
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "systemd-logind.service" ];
  #
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = [
  #       "${pkgs.bash}/bin/bash -c 'echo GPP0 > /proc/acpi/wakeup'"
  #       "${pkgs.bash}/bin/bash -c 'echo GPP8 > /proc/acpi/wakeup'"
  #     ];
  #   };
  # };

  system.stateVersion = "25.11";
}
