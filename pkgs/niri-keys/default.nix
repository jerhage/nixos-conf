# Searchable version of niri's Mod+Shift+Slash overlay, which cannot be
# filtered. Picking a bind runs it. Reads the live config, so edits to
# config.kdl need no rebuild.
{
  writeShellApplication,
  coreutils,
  findutils,
  fzf,
  gawk,
  ghostty,
  niri,
}:
writeShellApplication {
  name = "niri-keys";

  runtimeInputs = [
    coreutils
    findutils
    fzf
    gawk
    ghostty
    niri
  ];

  text = ''
    config="''${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
    if [ ! -r "$config" ]; then
      echo "no readable niri config at $config" >&2
      exit 1
    fi

    # Runs inside the terminal. Field 3 is the action, hidden from fzf.
    if [ "''${1-}" = "--pick" ]; then
      binds=$(mktemp)
      trap 'rm -f "$binds"' EXIT
      awk -f ${./binds.awk} "$config" > "$binds"
      fzf --delimiter='\t' --with-nth=1,2 --nth=1,2 \
          --no-sort --reverse --prompt="keys> " \
          --header="niri keybinds -- Enter runs the bind, Esc cancels" \
          < "$binds" > "$2" || true
      exit 0
    fi

    choice=$(mktemp)
    trap 'rm -f "$choice"' EXIT

    # Ghostty kills its process tree on exit, so the action has to run out
    # here. -e blocks until the window closes.
    ghostty --class=com.jh.niri-keys -e "$0" --pick "$choice" || true

    [ -s "$choice" ] || exit 0
    action=$(cut -f3 "$choice")
    [ -n "$action" ] || exit 0

    # KDL quotes like the shell does, so xargs keeps quoted args whole.
    mapfile -t argv < <(printf '%s' "$action" | xargs -n1 printf '%s\n')
    [ "''${#argv[@]}" -gt 0 ] || exit 0

    niri msg action "''${argv[0]}" -- "''${argv[@]:1}"
  '';
}
