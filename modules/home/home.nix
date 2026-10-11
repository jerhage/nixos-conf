{
  inputs,
  config,
  pkgs,
  ...
}:
{
  home.stateVersion = "25.05";

  imports = [
    ./waybar/waybar.nix
    ./niri/niri.nix
    ./bash.nix
    ./wofi.nix
    #./tmux.nix
    #./nvim.nix
    #./ghostty.nix
    ./git.nix
    ./mpv.nix

    inputs.zen-browser.homeModules.twilight # beta (default), twilight (bleeding-edge), twilight-official
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
  gtk = {
    enable = true;
    theme.name = "Adwaita-dark";

    colorScheme = "dark";
  };
  qt = {
    enable = true;
    style.name = "adwaita-dark";
  };
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.catppuccin-cursors.mochaSapphire;
    name = "catppuccin-mocha-sapphire-cursors";
    size = 16;
  };

  home.packages = with pkgs; [
    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      excludeShellChecks = [ "SC2016" ]; # remove after next release
      text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
    })
  ];
  ########################################
  # 🧬 Git config
  ########################################
  programs = {
    #go.enable = true;
    bash.enable = true;
    zoxide.enable = true;
    #obs-studio.enable = true;
    #obs-studio.plugins = [ pkgs.obs-studio-plugins.wlrobs ];
    zen-browser.enable = true;
    ssh = {
      matchBlocks = {
        "*" = {
          forwardAgent = false;
          addKeysToAgent = "yes";
        };
      };

      extraConfig = ''
        UseKeychain no
      '';
      # matchBlocks = {
      #   # nixos = {
      #   #   hostname = "10.10.1.202";
      #   #   user = "jh";
      #   #   identityFile = "~/.ssh/id_ed25519_nix";
      #   #   identitiesOnly = true;
      #   # };
      #   macbook = {
      #     # hostname = "macbook-pro.local";
      #     hostname = "10.10.1.115";
      #     user = "jh";
      #     identityFile = "~/.ssh/id_ed25519_nix";
      #     identitiesOnly = true;
      #   };
      # };
    };
  };

  services.ssh-agent.enable = true;
  home.file.".ssh/config".text = ''
    Host mbp
      HostName 10.10.1.115
      User jh
      IdentityFile ~/.ssh/id_ed25519_nix
      IdentitiesOnly yes
  '';

  services.awww.enable = true;
  services.swaync.enable = true;

}
