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

        power-profiles-daemon persists the last-selected profile to
        /var/lib/power-profiles-daemon/state.ini, so without this the profile is
        whatever was picked last -- including from the shell's power widget.
        Setting it here makes the boot state declarative: a profile changed at
        runtime is reset on the next boot.

        null leaves the daemon's persisted choice alone.
      '';
    };
  };

  # Noctalia's power widget and its `power-set`/`power-cycle` commands talk to
  # power-profiles-daemon over D-Bus; its battery/device widgets talk to upower.
  # Without these, those parts of the shell have nothing to show.
  config = lib.mkIf cfg.enable {
    # No /sys/firmware/acpi/platform_profile on this box, but the amd-pstate-epp
    # cpufreq driver gives p-p-d a working backend (performance/balanced/
    # power-saver via the Energy Performance Preference interface).
    services.power-profiles-daemon.enable = true;

    # Reports peripheral batteries too, e.g. the Logitech G305 as
    # hidpp_battery_0. Note those are scope=Device with coarse levels only
    # (full/good/low/critical), not a percentage, and the UPower DisplayDevice
    # aggregate reports "battery-missing" on a desktop with no system battery.
    services.upower.enable = true;

    # NixOS has no defaultProfile option, so apply it once the daemon is up.
    systemd.services.apply-power-profile = lib.mkIf (cfg.profile != null) {
      description = "Apply the configured power profile";
      wants = [ "power-profiles-daemon.service" ];
      after = [ "power-profiles-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set ${cfg.profile}";
      };
    };
  };
}
