{
  imports = [
    # always on
    ./nix.nix
    ./user.nix
    ./git.nix
    ./kernel.nix
    ./profiles.nix
    ./secrets.nix
    ./vm.nix

    # opt-in features
    ./accounting.nix
    ./apps.nix
    ./audio.nix
    ./bluetooth.nix
    ./cli.nix
    ./desktop.nix
    ./dns.nix
    ./devtools.nix
    ./dotfiles.nix
    ./fleet.nix
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
    ./power.nix
    ./shell.nix
    ./sync.nix
    ./sync-cloud.nix
    ./server.nix
    ./anki-sync.nix
    ./backup.nix
    ./tailscale.nix
    ./ssh.nix
    ./terminals.nix
    ./theming.nix
    ./keyboard.nix
    ./virtualisation.nix
    ./zram.nix
  ];
}
