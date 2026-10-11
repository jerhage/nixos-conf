{ config, ... }:
{
  # Wires the home-manager configuration to whichever user the host declares.
  home-manager.users.${config.my.user} = import ./home/home.nix;
}
