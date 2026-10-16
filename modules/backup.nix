{
  config,
  lib,
  ...
}:
let
  cfg = config.my.backup;
in
{
  options.my.backup = {
    enable = lib.mkEnableOption "restic snapshots to an rclone remote";

    repository = lib.mkOption {
      type = lib.types.str;
      default = "rclone:dropbox:restic";
      description = ''
        Where snapshots go. Not inside a crypt remote: restic already encrypts
        contents, filenames and structure, so crypt would be a second layer
        protecting nothing.
      '';
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "/var/lib/calibre" ];
      description = ''
        Directories to snapshot. Worth including service state, not just the
        obvious data: it exists nowhere else once the disk is gone.
      '';
    };

    keep = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
      description = "Retention passed to `restic forget`.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.restic-password.mode = "0400";

    services.restic.backups.local = {
      inherit (cfg) repository paths;
      initialize = true;

      passwordFile = "/run/secrets/restic-password";
      rcloneConfigFile = "/run/secrets/rclone-conf";

      timerConfig.OnCalendar = "daily";
      timerConfig.RandomizedDelaySec = "1h";

      pruneOpts = cfg.keep;
    };
  };
}
