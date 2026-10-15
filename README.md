# nixos-conf

NixOS configuration for all my machines. One directory per host under `hosts/`,
shared behaviour in opt-in modules under `modules/`.

The repo is checked out at `~/nixos-conf`, with no symlink indirection.

## Rebuild this machine

```sh
sudo nixos-rebuild switch --flake ~/nixos-conf
```

`nixos-rebuild` picks the host matching the current hostname, so no `#name` is
needed. To check without activating anything:

```sh
nixos-rebuild build --flake ~/nixos-conf        # builds ./result, activates nothing
nixos-rebuild dry-activate --flake ~/nixos-conf # shows which units a switch would touch
```

`build` leaves a `result` symlink, which Nix registers as a GC root -- it will
pin that whole system closure until removed. `rm -f result` when done, or use
`--no-link`.

## Add a new host

1. On the new machine, clone this repo.
2. `cp -r templates/host hosts/<hostname>`
3. `nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix`
4. Edit `hosts/<hostname>/default.nix`: set `my.user`, pick profiles, and set
   `system.stateVersion` to the NixOS release that machine was installed with.
5. `git add hosts/<hostname>` — flakes ignore untracked files.
6. `sudo nixos-rebuild switch --flake ~/nixos-conf#<hostname>`
   (the `#<hostname>` is only needed this first time, before the hostname is set)

The host directory name *is* the hostname; `flake.nix` contains no hostnames.

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Discovers hosts via `readDir ./hosts`. Never edited to add a host. |
| `modules/` | Shared NixOS modules, each behind a `my.<name>.enable` option. |
| `modules/default.nix` | Imports every module. Every host gets all of them; they do nothing unless enabled. |
| `modules/profiles.nix` | Bundles modules for a kind of machine (`base`, `workstation`). |
| `hosts/<name>/` | Per-machine config and its `hardware-configuration.nix`. |
| `pkgs/<name>/` | Packages defined here rather than in nixpkgs, pulled in with `callPackage`. |
| `templates/host/` | Starting point for a new host. |

Always on regardless of profile: `nix.nix`, `user.nix`, `git.nix`, `kernel.nix`,
`profiles.nix`.

## Profiles

`my.profiles.base` is the interactive-but-headless set: command-line tools, bash
configuration, ssh agent, dotfile links, networking and input methods.
`my.profiles.workstation` turns on `base` plus the graphical session: compositor,
desktop shell, portals, theming, audio, bluetooth, fonts, input device rules,
power management and mpv. A host normally sets one profile and then only its
hardware and machine-specific bits.

Everything a profile sets uses `lib.mkDefault`, so a host can override any of it
with a plain assignment.

## Conventions

- Packages live in the module that owns the feature, not in the host list, so
  enabling a feature brings its tools along without the host restating them.
- The host package list is for applications that are not tied to a module.
- Options that take a fixed set of values use `lib.types.enum`, so a typo fails
  at eval rather than silently resolving to something else. See
  `my.kernel.branch`, `my.power.profile` and `my.greeter.backend`.
- Which display manager greets at login is `my.greeter.backend`, set per host.
  Switching between them is one word; `none` means TTY login.
- `my.cli.enable` is the baseline command-line set, on for every host via the
  `base` profile. The test for inclusion is whether a headless machine would
  want it; desktop-only tools belong in the host list.
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
  repo minus `bash` and `nono`. Run one as
  `nono run --profile claude-dots --allow-cwd -- claude`.
- `my.dns.systemdResolved` is off by default and exists as a documented escape
  hatch: turn it on if DNS starts resolving intermittently, which usually means
  NetworkManager, Tailscale and a VPN are racing over `/etc/resolv.conf`.
- `my.sync.pulls.<name>` declares an rsync pull from another host and generates
  four aliases from it: `pull-<name>`, `-dry`, `-merge` and `-merge-dry`. The
  flags live in `my.sync.flags` so the mirror-vs-merge distinction is defined
  once rather than per alias.
- `nix fmt` formats every `.nix` file in the repo via `nixfmt-tree`. Run it
  after changes. Passing a directory to `nixfmt` directly is deprecated, so
  format single files as `nixfmt <file>` or use `nix fmt` for the tree.

## Per-project dev environments

System-wide toolchains come from `my.devtools.languages`. For a project that
needs a specific runtime version, scaffold a shell instead of installing it
globally:

```sh
nix flake init -t ~/nixos-conf#devshell   # plain flake, just packages on PATH
nix flake init -t ~/nixos-conf#devenv     # devenv, for language helpers and services
direnv allow                              # both ship an .envrc
```

Versions are pinned by the template's own `flake.lock`, so a project stays on
its runtime regardless of what the system has. `programs.direnv` with
`nix-direnv` is enabled by `my.devtools`, so entering a directory enters its
shell.

## Dotfiles

Application configs live in a separate dotfiles repo, each in its own native
format. Nix does not own their contents -- it only declares the symlinks, via
`my.dotfiles.links` in the host file:

```nix
my.dotfiles.links = {
  ".bashrc" = "bash/.bashrc";
  ".config/nvim" = "nvim/.config/nvim";
};
```

Each entry becomes a systemd-tmpfiles `L+` rule, applied on every switch and
again at login. The symlink points at the real file in the repo, so edits take
effect immediately with no rebuild. It is a declarative `stow`.

Three caveats:

- Removing an entry does not remove the symlink it already created. Prune by
  hand.
- There is no validation that the dotfiles repo is present; a missing source
  gives a dangling symlink.
- Do not point `stow` at a path that `my.dotfiles.links` also manages. Both
  create symlinks and neither knows about the other, so whichever ran last
  wins and the result depends on ordering. Pick one mechanism per path.
