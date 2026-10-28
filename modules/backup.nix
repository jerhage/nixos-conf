{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.backup;

  # Root only: these copies hold the same data as the databases.
  staging = "/var/lib/restic-sqlite";
in
{
  options.my.backup = {
    enable = lib.mkEnableOption ''
      restic snapshots to an rclone remote. Turns on `my.secrets.enable`, since
      the repository password and the rclone config both come from sops
    '';

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

        Symlinks are resolved at backup time, so the obvious path works even
        for a `DynamicUser` service whose state really lives in
        /var/lib/private. Verify with a restore, not a file count.
      '';
    };

    sqliteDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "/var/lib/calibre/metadata.db" ];
      description = ''
        SQLite databases to copy before the snapshot. In WAL mode a database is
        three files, which restic reads at different moments, so a checkpoint
        during the snapshot can cost the most recent transactions on restore.

        Each is copied with sqlite's online backup under ${staging}, keeping
        its path, and that copy is snapshotted as well. The live files stay in
        the snapshot too; the copy is the one to restore from.
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
    # Not optional: without it nothing sets defaultSopsFile.
    my.secrets.enable = true;

    sops.secrets.restic-password.mode = "0400";

    services.restic.backups.local = {
      inherit (cfg) repository;

      # Resolved at backup time, not written out by hand: a DynamicUser service
      # keeps its state in /var/lib/private/<name> and symlinks /var/lib/<name>
      # to it, and restic would otherwise snapshot the link and no data.
      dynamicFilesFrom = ''
        for p in ${lib.escapeShellArgs (cfg.paths ++ lib.optional (cfg.sqliteDatabases != [ ]) staging)}; do
          ${pkgs.coreutils}/bin/readlink -f "$p"
        done
      '';
      initialize = true;

      backupPrepareCommand = lib.mkIf (cfg.sqliteDatabases != [ ]) ''
        set -eu
        ${pkgs.coreutils}/bin/install -d -m 0700 ${staging}
        for db in ${lib.escapeShellArgs cfg.sqliteDatabases}; do
          real=$(${pkgs.coreutils}/bin/readlink -f "$db")
          dest=${staging}/''${real#/}
          ${pkgs.coreutils}/bin/install -d -m 0700 "$(${pkgs.coreutils}/bin/dirname "$dest")"
          ${pkgs.coreutils}/bin/rm -f "$dest"
          ${pkgs.sqlite}/bin/sqlite3 "$real" ".backup '$dest'"
        done
      '';

      # ExecStopPost, so a failed backup leaves no copies behind either.
      backupCleanupCommand = lib.mkIf (cfg.sqliteDatabases != [ ]) ''
        ${pkgs.coreutils}/bin/rm -rf ${staging}
      '';

      passwordFile = "/run/secrets/restic-password";
      rcloneConfigFile = "/run/secrets/rclone-conf";

      timerConfig.OnCalendar = "daily";
      timerConfig.RandomizedDelaySec = "1h";

      pruneOpts = cfg.keep;
    };
  };
}
