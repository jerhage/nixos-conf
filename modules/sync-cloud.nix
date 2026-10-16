{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.sync;
in
{
  options.my.sync.cloudFlags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "--progress"
      "--transfers"
      "32" # great for parallel uploads of smaller files like a calibre library
    ];
    description = ''
      rclone flags shared by every cloud entry.
    '';
  };

  options.my.sync.cloud = lib.mkOption {
    default = { };
    description = ''
      Syncs against an rclone remote. Each entry `<name>` generates:

      - `push-<name>`       mirror up: `rclone sync`, so files deleted
                            locally are deleted on the remote
      - `push-<name>-dry`   the same, with `--dry-run`
      - `pull-<name>`       merge down: `rclone copy`, which never deletes
      - `pull-<name>-dry`   the same, with `--dry-run`

      The directions are deliberately asymmetric. Pulling is a restore, and a
      restore that deletes local files not yet uploaded is a bad trade.

      Needs an `rclone-conf` secret; the aliases read it from `/run/secrets`
      rather than `~/.config/rclone`, so the token is never in a dotfile.
    '';
    example = {
      docs = {
        local = "~/docs/";
        remote = "crypt:docs/";
      };
    };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          local = lib.mkOption {
            type = lib.types.str;
            description = "Local directory. A trailing slash copies the contents.";
          };
          remote = lib.mkOption {
            type = lib.types.str;
            description = "rclone target, as `<remote>:<path>`.";
          };
          extraFlags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Flags for this entry only.";
          };
        };
      }
    );
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = (lib.intersectLists (lib.attrNames cfg.pulls) (lib.attrNames cfg.cloud)) == [ ];
          message = "my.sync.pulls and my.sync.cloud share a name, so both would define the same pull-<name> alias.";
        }
      ];
    }

    (lib.mkIf (cfg.cloud != { }) {
      environment.systemPackages = [ pkgs.rclone ];

      # The config holds the oauth token and the crypt passwords, so it lives
      # in sops and is readable only by the user running the aliases.
      sops.secrets.rclone-conf = {
        owner = config.my.user;
        mode = "0400";
      };

      environment.shellAliases = lib.concatMapAttrs (
        name: c:
        let
          run =
            verb: args:
            lib.concatStringsSep " " (
              [
                "rclone"
                "--config"
                "/run/secrets/rclone-conf"
                verb
              ]
              ++ cfg.cloudFlags
              ++ c.extraFlags
              ++ args
            );
        in
        {
          "push-${name}" = run "sync" [
            c.local
            c.remote
          ];
          "push-${name}-dry" = run "sync" [
            "--dry-run"
            c.local
            c.remote
          ];
          "pull-${name}" = run "copy" [
            c.remote
            c.local
          ];
          "pull-${name}-dry" = run "copy" [
            "--dry-run"
            c.remote
            c.local
          ];
        }
      ) cfg.cloud;
    })
  ];
}
