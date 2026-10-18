# Options

What each `my.*` option does and why it is shaped that way. For layout and
profiles see [reference.md](reference.md); for restoring data see
[backups.md](backups.md).

- Packages live in the module that owns the feature, not in the host list, so
  enabling a feature brings its tools along without the host restating them.
- The host package list is for applications that are not tied to a module.
- Options that take a fixed set of values use `lib.types.enum`, so a typo fails
  at eval rather than silently resolving to something else. See
  `my.kernel.branch`, `my.power.profile` and `my.greeter.backend`.
- Which display manager greets at login is `my.greeter.backend`. It defaults to
  `none` so a headless host gets no display manager, and
  `my.profiles.workstation` sets `ly`. Switching is one word; a host that wants
  something else assigns it directly, as nucleus does with `noctalia`.
- `my.cli.enable` is the baseline command-line set, on for every host via the
  `base` profile. The test for inclusion is whether a headless machine would
  want it; desktop-only tools belong in the host list.
- `my.i18n.languages` adds a locale per language, and the matching fcitx5 engine
  only when `my.i18n.inputMethod.enable` is also on. `base` sets locales, which
  any host needs to handle CJK filenames; `workstation` adds the input method,
  which needs a graphical session.
- `my.devtools.languages` takes a list of toolchain names and installs a
  complete set for each -- `rust` means rustc and rust-analyzer, not just cargo.
  Typed as an enum, so an unknown name fails at eval. Current sets: bun, c,
  deno, elixir, go, nix, node, python, rust.
- `my.devtools.agentSandbox` installs nono, a Landlock sandbox for AI agent
  harnesses. The option installs the tool only. Profiles are not managed by Nix:
  they live in `~/dotfiles/nono` and the whole `profiles` directory is linked by
  `my.dotfiles.links`, so adding one is just a new file there. Two lines of them
  -- `agent` and `agent-dots` extend nono's own `default` and suit any harness,
  while `claude-base` and `claude-dots` extend the Claude Code profile that
  `nono pull nolabs-ai/claude` installs. The `-dots` variants add the dotfiles
  repo minus `bash` and `nono`. Launch with `sandbox`, below, rather than
  calling `nono run` directly.
- `sandbox` comes with `my.devtools.agentSandbox` and is the launcher to use:
  `sandbox [--profile <name>] [nono options --] <command> [args...]`, so
  `sandbox --profile agent-dots claude --resume` and `sandbox pi` both work.
  Options stop at the first non-option, so the harness gets its own argv
  untouched, even a `--profile` of its own. Everything before the command is
  for `nono run`: `--profile` is captured, which is what lets
  `my.devtools.sandboxProfile` supply it when absent and keeps nono receiving
  exactly one, and the rest is forwarded verbatim. Use a `--` when a forwarded
  option takes a value, as `sandbox --allow /srv/data -- claude` does, or the
  value is mistaken for the command.
  It denies the agent every private network range, listed in
  `my.devtools.sandboxDenyRanges`, which nono cannot do -- nono's network rules
  are hostnames and ports, so a deny there is bypassed by connecting to a bare
  address. The ranges are enforced by systemd `IPAddressDeny`, which only
  attaches for system units, so the launcher needs `sudo` and prompts once.
- `my.ssh.server.interfaces` lists the interfaces that accept SSH; port 22 is
  opened per interface rather than globally, so bringing up wifi, a VM bridge or
  a container veth does not expose sshd on it. Defaults to `[ "tailscale0" ]`,
  so a new host is tailnet-only until it opts into more. Interface names are
  host-specific (`ip -br link`), which is why the list lives on the host.
- `my.dns.systemdResolved` is off by default and exists as a documented escape
  hatch: turn it on if DNS starts resolving intermittently, which usually means
  NetworkManager, Tailscale and a VPN are racing over `/etc/resolv.conf`.
- `my.sync.cloud.<name>` syncs against an rclone remote. `push-<name>` mirrors
  and deletes; `pull-<name>` only merges, because a restore should never remove
  local files.
- `my.server.sites.<name>` publishes a service through Caddy. `routing = "path"`
  serves everything on one origin behind a single `tailscale serve`, and sets
  the prefix headers apps need; `routing = "host"` switches to subdomains later
  without touching the service definitions. `cors = [ "https://app.example" ]`
  allows browser javascript on those origins to call the service, answering the
  preflight in Caddy so the app behind it never sees an `OPTIONS`.
- `my.tailscale.tailnet` holds the MagicDNS suffix so a config can name another
  host on the tailnet -- `"https://nucleus.${config.my.tailscale.tailnet}"` --
  and `my.tailscale.fqdn` is this host's own name.
- `my.backup`, `my.ankiSync` and `my.sync.cloud` each set
  `my.secrets.enable = true`, since all three read a secret from sops and none
  can run without it. Enabling any of them turns sops on without the host file
  saying so.
- `my.secrets.enable` turns on sops-nix. A host decrypts with an age key derived
  from its ssh host key, so reinstalling one means re-running `ssh-to-age`, adding
  it to `.sops.yaml` and `sops updatekeys`. Hosts only decrypt the secrets they
  declare. Full procedure, and what has to be in 1Password, in
  [secrets.md](secrets.md).
- `my.sync.pulls.<name>` declares an rsync pull from another host and generates
  `pull-<name>` and `-dry`, which merge. `mirror = true` adds the deleting
  variants: deletion is opt-in per entry rather than something to remember.
  Shared flags live in `my.sync.flags`.
- `nix fmt` formats every `.nix` file in the repo via `nixfmt-tree`. Run it
  after changes. Passing a directory to `nixfmt` directly is deprecated, so
  format single files as `nixfmt <file>` or use `nix fmt` for the tree.

## trusted-users

`modules/nix.nix` sets `nix.settings.trusted-users = [ "root" my.user ]` on
every host. `nixos-rebuild --target-host` copies an unsigned closure, and the
target refuses it unless the pushing user is trusted:

```
error: cannot add path '/nix/store/...' because it lacks a signature by a trusted key
```

Being trusted means that user can put arbitrary paths into the store and set
their own nix settings, which is root-equivalent on that machine. It is granted
here because jh already has sudo on both hosts, so it widens nothing in
practice.

That stops being true the moment a host has a user who should not be root
there, or an agent runs as that user with network access. Two ways to narrow
it:

Move the setting out of `modules/nix.nix` and into the host files that are push
targets, so a laptop is not a trusted pusher just by existing:

```nix
nix.settings.trusted-users = [
  "root"
  config.my.user
];
```

Or drop it entirely and sign the closures instead. Generate a key pair with
`nix-store --generate-binary-cache-key`, give the target the public half in
`nix.settings.trusted-public-keys`, and sign on the builder with
`nix store sign --key-file`. More moving parts, but it authenticates the
closure rather than the user, which is the right shape once more than one
person or machine can push.
