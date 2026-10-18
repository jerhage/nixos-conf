{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.accounting;
in
{
  options.my.accounting.enable = lib.mkEnableOption ''
    plain text accounting: beancount and the fava web interface. Off by
    default, since it is a workflow rather than part of a workstation
  '';

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      beancount
      fava
    ];
  };
}
