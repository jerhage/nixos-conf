# Runs an agent harness under nono, in a systemd unit that denies the private
# network ranges nono has no way to express.
{
  lib,
  writeShellApplication,
  systemd,
  nono,
  profile,
  denyRanges,
}:
writeShellApplication {
  name = "sandbox";

  text = ''
    profile="${profile}"
    nono_args=()

    # Options before the command are nono's; -- when one of them takes a value.
    sep=0
    for a in "$@"; do
      if [ "$a" = "--" ]; then
        sep=1
        break
      fi
    done

    while [ "$#" -gt 0 ]; do
      if [ "$sep" -eq 1 ] && [ "$1" = "--" ]; then
        shift
        break
      fi
      case $1 in
        --profile)
          if [ -z "''${2:-}" ]; then
            echo "sandbox: --profile needs a name" >&2
            exit 2
          fi
          profile=$2
          shift 2
          ;;
        --profile=*)
          profile=''${1#*=}
          shift
          ;;
        -*)
          nono_args+=( "$1" )
          shift
          ;;
        *)
          if [ "$sep" -eq 1 ]; then
            nono_args+=( "$1" )
            shift
          else
            break
          fi
          ;;
      esac
    done

    if [ "$#" -eq 0 ]; then
      echo "usage: sandbox [--profile <name>] [nono options --] <command> [args...]" >&2
      exit 2
    fi

    deny=( ${lib.concatMapStringsSep " " (r: "-p IPAddressDeny=${r}") denyRanges} )
    user=$(id -un)

    # sudo: IPAddressDeny only attaches for system units, and it has to be the
    # setuid wrapper. WorkingDirectory: a system unit would start in /.
    exec sudo ${systemd}/bin/systemd-run --pty --quiet \
      --uid="$user" \
      -p WorkingDirectory="$PWD" \
      -p "Environment=PATH=/run/wrappers/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$user/bin:/run/current-system/sw/bin" \
      "''${deny[@]}" \
      ${nono}/bin/nono run --profile "$profile" "''${nono_args[@]}" -- "$@"
  '';
}
