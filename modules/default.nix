{
  imports = [
    # always on
    ./nix.nix
    ./user.nix
    ./git.nix
    ./home-manager.nix
    ./profiles.nix

    # opt-in features
    ./audio.nix
    ./bluetooth.nix
    ./desktop.nix
    ./fonts.nix
    ./gaming.nix
    ./i18n.nix
    ./networking.nix
    ./niri.nix
    ./nvidia.nix
    ./onepassword.nix
    ./openssh.nix
    ./tor.nix
    ./udev.nix
    ./virtualisation.nix
    ./zram.nix
  ];
}
