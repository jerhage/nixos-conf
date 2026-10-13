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

    # No after/wants on power-profiles-daemon: it ships After=multi-user.target,
    # which cycles with wantedBy and makes systemd drop this job. powerprofilesctl
    # activates it over D-Bus regardless.
    systemd.services.apply-power-profile = lib.mkIf (cfg.profile != null) {
      description = "Apply the configured power profile";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set ${cfg.profile}";
      };
    };
  };
}
