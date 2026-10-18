{ config, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  my.user = "jh";

  my.profiles.workstation.enable = true;

  my.tailscale.enable = true;
  my.tailscale.tailnet = "tail5e24fe.ts.net";

  # Tailnet only, the default. A laptop joins untrusted networks, and opening
  # 22 on the wifi interface would open it on every one of them.
  my.ssh.server.enable = true;

  my.devtools.enable = true;

  # Until the dotfiles repo is cloned here, every link would dangle.
  my.dotfiles.enable = false;

  users.users.${config.my.user} = {
    description = "Main User";
    extraGroups = [ "networkmanager" ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Chicago";

  # The NixOS release this machine was INSTALLED with. Never bump this.
  system.stateVersion = "26.05";
}
