# Reference

Repository layout, profiles, and the per-project and dotfile workflows.
Option-by-option notes are in [options.md](options.md), restoring data in
[backups.md](backups.md).

## Layout

| Path                   | Purpose                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------- |
| `flake.nix`            | Discovers hosts via `readDir ./hosts`. Never edited to add a host.                 |
| `modules/`             | Shared NixOS modules, each behind a `my.<name>.enable` option.                     |
| `modules/default.nix`  | Imports every module. Every host gets all of them; they do nothing unless enabled. |
| `modules/profiles.nix` | Bundles modules for a kind of machine (`base`, `workstation`).                     |
| `hosts/<name>/`        | Per-machine config and its `hardware-configuration.nix`.                           |
| `pkgs/<name>/`         | Packages defined here rather than in nixpkgs, pulled in with `callPackage`.        |
| `templates/host/`      | Starting point for a new host.                                                     |

Always on regardless of profile, having no enable option of their own:
`git.nix`, `greeter.nix`, `kernel.nix`, `nix.nix`, `user.nix`, plus `sync.nix`,
`sync-cloud.nix` and `vm.nix`, which are inert until something is configured.
They are all inert until configured: `greeter.nix` defaults `backend` to
`none`, and `my.profiles.workstation` is what sets `ly`.

## Profiles

`my.profiles.base` is the interactive-but-headless set: command-line tools, bash
configuration, ssh agent, dotfile links, networking and input methods.
`my.profiles.workstation` turns on `base` plus the graphical session: compositor,
desktop shell, portals, theming, audio, bluetooth, fonts, input device rules,
power management and mpv. A host normally sets one profile and then only its
hardware and machine-specific bits.

Everything a profile sets uses `lib.mkDefault`, so a host can override any of it
with a plain assignment.

## Trying a host config in a VM

A host directory can be built and booted as a VM before the machine exists.
cortex was written this way: the services, Caddy routing and secrets were all
working in a VM first, and only the parts needing real hardware -- the disk
layout, the ssh host key the age key derives from, the 20 GB library -- waited
for the physical box.

```sh
nixos-rebuild build-vm --flake ~/nixos-conf#<hostname>
./result/bin/run-<hostname>-vm
```

The guest boots to a console in the terminal; `poweroff` exits. The login
password is `nixos`, set by `initialPassword` in the VM variant only.

`my.vm.graphics` opens a QEMU window instead, off by default because a host
configured for a real GPU rarely boots graphically under emulation.
`my.vm.shareDotfiles` mounts the dotfiles repo over 9p so the links resolve to
the same files; with it off the links are disabled entirely, since without the
repo every one of them dangles.

What a VM will not tell you: anything about the disk, firmware or network
hardware, and anything keyed to the host's identity. sops is the clearest case,
since the age key is derived from the ssh host key, so a VM cannot decrypt the
host's secrets and those paths stay untested until the real machine runs.

[vm-workflow.md](vm-workflow.md) has the long version: how cortex was built
this way, what the guest is useful for checking, and the things that looked
correct in a VM and still broke on hardware.

## Updating

### Where packages come from

One revision of nixpkgs, pinned in `flake.lock` and selected by the
`nixos-26.05` branch in `flake.nix`. Channels are off, and both
`nix.registry.nixpkgs` and `nix.nixPath` point at that same input, so
`nix shell nixpkgs#foo`, `nix run`, `nix-shell -p foo`, `<nixpkgs>` and `,` all
resolve to the revision the system was built from.

The consequence: nothing gets newer on its own. A package released yesterday is
not reachable until the lock moves, and `nix shell nixpkgs#foo` will keep
handing over the system's version however long that is. That is the trade for
never getting a binary from a nixpkgs the system does not run.

### Routine update

```sh
nix flake update                 # every input
nix flake update nixpkgs         # or just one
git diff flake.lock              # what moved, before building anything
os-diff                          # build, show the package diff, then ask
```

Answer no at the prompt and nothing changed. Commit `flake.lock` once a switch
works, since that file is the record of what is running.

For the other hosts, push and then:

```sh
os-push cortex
```

If a switch boots badly, the previous generation is in the boot menu, or
`sudo nixos-rebuild switch --rollback` goes back without rebooting.

### Moving to a new nixpkgs release

Release branches are `nixos-YY.MM`, roughly May and November. To go from 26.05
to 26.11:

1. Read the release notes first, specifically the incompatibilities section.
   This is the one upgrade where options get renamed or removed under you.
2. Change the branch in `flake.nix`:
   `nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.11";`
3. `nix flake update nixpkgs`. Every input that `follows` nixpkgs moves with it.
4. Build each host without activating anything:
   `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
   for a cheap eval, then `nixos-rebuild build --flake .#<host>` to compile.
   Eval errors here are renamed or removed options, and they are the whole
   point of doing this step before switching.
5. Switch the least important host first.

Leave `system.stateVersion` alone. It records the release a host was *installed*
with, not the release it runs, and exists so stateful defaults keep their old
behaviour. nucleus is `25.11` and cortex is `26.05` for that reason, and
bumping either on an upgrade is how you silently change the semantics of things
like default database versions.

Two inputs track something other than a release branch and so may need their own
attention: `noctalia-greeter`, whose module is unstable-only until it reaches
stable, and `nono`, which nixpkgs lags behind.

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
format. Nix does not own their contents, only the symlinks, declared through
`my.dotfiles.links`.

`modules/dotfiles.nix` holds the whole map, keyed on the feature that owns each
path, so enabling a module brings its config with it:

```nix
my.dotfiles.links = lib.mkMerge [
  (lib.mkIf config.my.niri.enable { ".config/niri" = "niri/.config/niri"; })
  (lib.mkIf config.my.i18n.inputMethod.enable { ... })
];
```

Deliberately here and not in `niri.nix`. A feature module that referenced
`my.dotfiles.links` could not be imported on its own, since the option would
not exist in someone else's configuration, and it would encode this repo's
dotfiles layout. `niri.nix`, `mpv.nix`, `cli.nix`, `shell.nix`, `theming.nix`
and `devtools.nix` reference no `my.*` option but their own, so any of them can
be dropped into another config. `dotfiles.nix` is the one module nobody else
would want, which makes it the right place to keep the coupling.

The cost is that adding a feature with config means touching two files. The
benefit, besides portability, is one place to read what claims which path.

No host declares any links. An application whose config is tracked gets a
module so the map has something to key on, which is why `my.terminals` exists
for ghostty and wezterm rather than leaving them in a host's package list.

Each entry becomes a systemd-tmpfiles `L+` rule, applied on every switch and
again at login. The symlink points at the real file in the repo, so edits take
effect immediately with no rebuild. It is a declarative `stow`.

Four caveats:

- Removing an entry does not remove the symlink it already created. Prune by
  hand.
- There is no validation that the dotfiles repo is present; a missing source
  gives a dangling symlink.
- Do not point `stow` at a path that `my.dotfiles.links` also manages. Both
  create symlinks and neither knows about the other, so whichever ran last
  wins and the result depends on ordering. Pick one mechanism per path.
- A module contributes its links whether or not `my.dotfiles.enable` is on.
  That is harmless, since nothing reads them when it is off, which is how
  cortex enables `my.cli` without acquiring a dangling `.config/nvim`.
- A host cannot delete an entry a module declared, because the module system
  has no way to remove an attribute. Set it to null instead:

  ```nix
  my.dotfiles.links.".config/niri" = null;
  ```

  The path is then left alone rather than linked. This is for taking a path
  back while experimenting, when you want a hand written config that survives
  a switch, since the `L+` rule would otherwise replace it. It is not the way
  to give a host a different config: that belongs in the dotfiles repo, keyed
  on hostname. Expect zero of these in steady state.
