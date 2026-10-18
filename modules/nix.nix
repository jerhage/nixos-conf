{ config, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Lets this user push an unsigned closure here, which is what
      # `nixos-rebuild --target-host` does. Root-equivalent on this host.
      trusted-users = [
        "root"
        config.my.user
      ];

      # Free space mid-build instead of failing: once free space drops below
      # min-free, nix collects until it reaches max-free.
      min-free = 10 * 1024 * 1024 * 1024;
      max-free = 50 * 1024 * 1024 * 1024;
    };

    # Deliberately keep gc on upstream nix rather than nh clean. NH runs
    # unattended as root, so a silent break would go unnoticed and I feel better about leaving gc to 1st party config.
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 30d";
    };

    # Hardlink identical files in the store. Weekly, and slow on a large store.
    optimise.automatic = true;
  };

  # nix.gc skips direnv gcroots; clear them by hand:
  #   nh clean all --keep 5 --keep-since 30d
  programs.nh = {
    enable = true;
    flake = "/home/${config.my.user}/nixos-conf";
  };

  # Builds and shows the diff, then asks. Answer no to leave the system alone.
  environment.shellAliases.os-diff = "nh os switch --ask --diff always";
}
