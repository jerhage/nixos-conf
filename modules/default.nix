{
  imports = [
    # always on
    ./nix.nix
    ./user.nix
    ./git.nix
    ./kernel.nix
    ./profiles.nix

    # opt-in features
    ./audio.nix
    ./bluetooth.nix
    ./desktop.nix
    ./dns.nix
    ./devtools.nix
    ./dotfiles.nix
    ./fonts.nix
    ./gaming.nix
    ./greeter.nix
    ./i18n.nix
    ./mpv.nix
    ./networking.nix
    ./niri.nix
    ./noctalia.nix
    ./nvidia.nix
    ./onepassword.nix
    ./ssh-server.nix
    ./power.nix
    ./shell.nix
    ./sync.nix
    ./tailscale.nix
    ./ssh-agent.nix
    ./theming.nix
    ./keyboard.nix
    ./virtualisation.nix
    ./zram.nix
  ];
}
