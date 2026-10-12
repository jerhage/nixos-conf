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
    ./dotfiles.nix
    ./fonts.nix
    ./gaming.nix
    ./i18n.nix
    ./mpv.nix
    ./networking.nix
    ./niri.nix
    ./noctalia.nix
    ./nvidia.nix
    ./onepassword.nix
    ./openssh.nix
    ./power.nix
    ./shell.nix
    ./ssh.nix
    ./theming.nix
    ./tor.nix
    ./udev.nix
    ./virtualisation.nix
    ./zram.nix
  ];
}
