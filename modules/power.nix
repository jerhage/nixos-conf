{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.power;
in
{
  options.my.power = {
    enable = lib.mkEnableOption "power profiles and device battery reporting";

    profile = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "performance"
          "balanced"
          "power-saver"
        ]
      );
      default = null;
      description = ''
        Power profile to apply at boot.

        power-profiles-daemon persists the last-selected profile, so without
        this the profile is whatever was picked last, including from the shell's
        power widget. null leaves that persisted choice alone.
      '';
    };
  };

  # Noctalia's power and battery widgets read these over D-Bus.
  config = lib.mkIf cfg.enable {
    services.power-profiles-daemon.enable = true;

    # Covers peripheral batteries, e.g. Logitech devices like the G305 as hidpp_battery_0.
    services.upower.enable = true;

    # powerprofilesctl builds its valid values by querying the daemon, so it has
    # to run after it. The daemon is dbus-activated and never starts at boot on
    # its own, hence wants. Anchored to graphical.target because the daemon is
    # After=multi-user.target, which would cycle.
    systemd.services.apply-power-profile = lib.mkIf (cfg.profile != null) {
      description = "Apply the configured power profile";
      wants = [ "power-profiles-daemon.service" ];
      after = [ "power-profiles-daemon.service" ];
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set ${cfg.profile}";
      };
    };
  };
}
