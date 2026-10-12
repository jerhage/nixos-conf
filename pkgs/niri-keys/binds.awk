# Turns the binds block of a niri config.kdl into tab-separated records:
#
#   key <TAB> description <TAB> action
#
# The description is hotkey-overlay-title when the bind sets one, otherwise the
# action itself. The action keeps its KDL quoting so the caller can split it
# into argv for `niri msg action`. Binds with hotkey-overlay-title=null are
# skipped, matching what niri's own overlay hides.

/^[[:space:]]*binds[[:space:]]*\{/ { inbinds = 1; next }
inbinds && /^\}/                   { inbinds = 0 }
!inbinds                           { next }
/^[[:space:]]*\/\//                { next }
/hotkey-overlay-title=null/        { next }

match($0, /^[[:space:]]+[A-Za-z][A-Za-z0-9+_]*[[:space:]]/) {
  if (!match($0, /\{[^}]*\}/)) next
  action = substr($0, RSTART + 1, RLENGTH - 2)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", action)
  sub(/;$/, "", action)

  if (match($0, /hotkey-overlay-title="[^"]*"/)) {
    label = substr($0, RSTART + 22, RLENGTH - 23)
  } else {
    label = action
    gsub(/"/, "", label)
  }
  printf "%s\t%s\t%s\n", $1, label, action
}
