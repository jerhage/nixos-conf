{ config, lib, pkgs, ... }:
let
  cfg = config.my.sync;
in
{
  options.my.sync = {
    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-avhP"
        "--timeout=60"
      ];
      description = ''
        rsync flags shared by every pull, for both the mirror and merge
        variants. `--delete` is not here; it is added only to the mirror
        aliases.

        `--append-verify` is deliberately absent -- it assumes the local file is
        a prefix of the remote one, which is wrong when a file changes in place.
        `-P` still gives `--partial`, so interrupted transfers resume through the
        normal delta algorithm.
      '';
    };

    pulls = lib.mkOption {
      default = { };
      description = ''
        One-way syncs from a remote into a local directory. Each entry `<name>`
        generates four aliases:

        - `pull-<name>`           mirror: adds `--delete`, so local files the
                                  remote no longer has are removed
        - `pull-<name>-dry`       the same, with `--dry-run`
        - `pull-<name>-merge`     merge: no `--delete`, local-only files survive
        - `pull-<name>-merge-dry` the same, with `--dry-run`

        Both variants still overwrite local files that differ from the remote,
        so the dry runs are worth using either way.
      '';
      example = {
        calibre = {
          from = "mbp:~/calibre/";
          to = "~/calibre/";
        };
      };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            from = lib.mkOption {
              type = lib.types.str;
              description = "rsync source. A trailing slash copies the contents, not the directory.";
            };
            to = lib.mkOption {
              type = lib.types.str;
              description = "Local destination.";
            };
            extraFlags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Flags for this pull only, appended after my.sync.flags.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf (cfg.pulls != { }) {
    environment.systemPackages = [ pkgs.rsync ];

    environment.shellAliases = lib.concatMapAttrs (
      name: p:
      let
        run = extra: lib.concatStringsSep " " ([ "rsync" ] ++ cfg.flags ++ p.extraFlags ++ extra ++ [ p.from p.to ]);
      in
      {
        "pull-${name}" = run [ "--delete" ];
        "pull-${name}-dry" = run [ "--delete" "--dry-run" ];
        "pull-${name}-merge" = run [ ];
        "pull-${name}-merge-dry" = run [ "--dry-run" ];
      }
    ) cfg.pulls;
  };
}
