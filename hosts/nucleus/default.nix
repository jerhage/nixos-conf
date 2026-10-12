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
  my.sshServer.enable = true;
  my.devtools.enable = true;

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
    # cli / system
    bat
    btop
    dysk
    fastfetch
    fd
    ffmpeg
    fzf
    jq
    nh
    pv
    ripgrep
    starship
    stow
    tmux
    unzip
    usbutils # lsusb, usb-devices
    wev # wayland event viewer
    yazi
    zstd

    # dev
    cargo
    gcc
    git
    gnumake
    go
    gopls
    lazydocker
    lazygit
    neovim
    nixfmt-rfc-style
    nodejs_24
    pnpm
    tree-sitter
    typescript

    # network / security
    curl
    nmap
    openvpn
    proton-vpn
    rclone
    wget

    # desktop applications
    anki
    calibre
    calibre-web
    cryptomator
    discord
    dropbox
    gcolor3
    ghostty
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
  system.stateVersion = "25.11";
}
