{ config, lib, ... }:
{
  options.my.profiles.base.enable = lib.mkEnableOption "interactive user environment, no graphics";

  config = lib.mkIf config.my.profiles.base.enable {
    my.cli.enable = lib.mkDefault true;
    my.shell.enable = lib.mkDefault true;
    my.ssh.agent.enable = lib.mkDefault true;
    my.dotfiles.enable = lib.mkDefault true;
    my.networking.enable = lib.mkDefault true;
    my.i18n.enable = lib.mkDefault true;
  };
}
