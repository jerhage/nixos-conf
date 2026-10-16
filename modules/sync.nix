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
  options.my.sync = {
    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-avhP"
        "--timeout=60"
      ];
      description = ''
        rsync flags shared by every pull, for both the mirror and merge
        variants. `--delete` is not here; it is added only by the mirror
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
        One-way syncs from a remote into a local directory. Each entry
        `<name>` generates:

        - `pull-<name>`           merge: local-only files survive
        - `pull-<name>-dry`       the same, with `--dry-run`

        With `mirror = true` it generates four instead, where `pull-<name>`
        adds `--delete` and the merge behaviour moves to `pull-<name>-merge`.

        Every variant still overwrites local files that differ from the
        remote, so the dry runs are worth using either way.
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
            mirror = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Generate the deleting variants as well. Off by default:
                `--delete` removes local files the remote does not have, so
                it is opt-in per entry rather than something to remember.
              '';
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
        run =
          extra:
          lib.concatStringsSep " " (
            [ "rsync" ]
            ++ cfg.flags
            ++ p.extraFlags
            ++ extra
            ++ [
              p.from
              p.to
            ]
          );
      in
      if p.mirror then
        {
          "pull-${name}" = run [ "--delete" ];
          "pull-${name}-dry" = run [
            "--delete"
            "--dry-run"
          ];
          "pull-${name}-merge" = run [ ];
          "pull-${name}-merge-dry" = run [ "--dry-run" ];
        }
      else
        {
          "pull-${name}" = run [ ];
          "pull-${name}-dry" = run [ "--dry-run" ];
        }
    ) cfg.pulls;
  };
}
