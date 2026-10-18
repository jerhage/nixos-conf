{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  # Required. No default: the build fails if this is missing.
  my.user = "CHANGEME";

  # Pick the bundles this machine wants.
  my.profiles.workstation.enable = true;

  # Which greeter logs you in. One of: ly, noctalia, none.
  # workstation sets "ly"; "noctalia" needs the noctalia-greeter flake input.
  # my.greeter.backend = "noctalia";

  # Machine-specific capabilities (see modules/ for the full list).
  # my.nvidia.enable = true;
  # my.zram.enable = true;
  # my.gaming.enable = true;
  # my.virtualisation.enable = true;
  # my.ssh.server.enable = true;
  # my.devtools.enable = true;

  # Kernel branch. Omit for the nixpkgs default (same as NixOS would pick).
  # One of: default, latest, zen, xanmod, lts_6_12
  # my.kernel.branch = "latest";

  # Override the shared git identity if this machine needs a different one.
  # my.git.userEmail = "work@example.com";

  # rsync pulls from another host. Each entry generates pull-<name>,
  # pull-<name>-dry, pull-<name>-merge and pull-<name>-merge-dry.
  # my.sync.pulls.calibre = {
  #   from = "mbp:~/calibre/";
  #   to = "~/calibre/";
  # };

  boot.loader = {
    systemd-boot.enable = true;
  };

  time.timeZone = "America/Chicago";

  users.users.${config.my.user} = {
    description = "Main User";
    # "wheel" is already added by modules/user.nix
    extraGroups = [ ];
    openssh.authorizedKeys.keys = [ ];
  };

  environment.systemPackages = with pkgs; [ ];

  # The NixOS release this machine was INSTALLED with. Never bump this.
  system.stateVersion = "CHANGEME";
}
