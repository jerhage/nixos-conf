{ config, lib, ... }:
{
  options.my.profiles.server.enable = lib.mkEnableOption ''
    a headless machine that runs services: no graphical session, and the disk
    and log hygiene a desktop does not need
  '';

  config = lib.mkIf config.my.profiles.server.enable {
    my.profiles.base.enable = lib.mkDefault true;
    my.ssh.server.enable = lib.mkDefault true;

    # Weekly TRIM. Nothing else schedules it.
    services.fstrim.enable = lib.mkDefault true;

    # Disk health. Reports to the journal only until there is somewhere to send
    # a notification, and the unit fails on a disk with no SMART support.
    services.smartd.enable = lib.mkDefault true;

    # Otherwise the journal grows until the disk is full, which on a host whose
    # whole job is storing things is the wrong way to run out of space.
    services.journald.extraConfig = lib.mkDefault "SystemMaxUse=1G";

    # Nothing should put a machine that serves to sleep.
    systemd.sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };
}
