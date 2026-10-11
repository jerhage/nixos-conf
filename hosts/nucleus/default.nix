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

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
  };
  boot.kernelPackages = pkgs.linuxPackages;

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
  # effect without a rebuild. The waybar/wofi/swaylock entries go away when
  # noctalia replaces them.
  my.dotfiles = {
    links = {
      # shell
      ".bashrc" = "bash/.bashrc";
      ".profile" = "bash/.profile";

      # ssh
      ".ssh/config" = "ssh/.ssh/config";

      # app configs
      ".config/git/config" = "git/.config/git/config";
      ".config/mpv/mpv.conf" = "mpv/.config/mpv/mpv.conf";
      ".config/niri" = "niri/.config/niri";
      ".config/gtk-3.0/settings.ini" = "gtk/.config/gtk-3.0/settings.ini";
      ".config/gtk-4.0/settings.ini" = "gtk/.config/gtk-4.0/settings.ini";
      ".gtkrc-2.0" = "gtk/.gtkrc-2.0";

      # superseded by noctalia later
      ".config/waybar" = "waybar/.config/waybar";
      ".config/wofi" = "wofi/.config/wofi";
      ".config/swaylock" = "swaylock/.config/swaylock";
    };

    extraRules = [ "d %h/.ssh 0700 - - -" ];
  };

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
    waybar-mpris
    playerctl
    waypaper
    waybar
    swaylock-effects
    nvidia-vaapi-driver
    nvidia-modprobe
    swaynotificationcenter
    neovim
    wget
    wl-clipboard-rs
    git
    glib
    steam-run
    curl
    wlogout
    discord
    obs-studio
    spotify
    # lsd
    bat
    tmux
    fzf
    lazygit
    lazydocker
    wofi
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
    steam
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
