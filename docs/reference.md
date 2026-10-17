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
`greeter.nix` is the one to watch: it defaults `backend` to `ly`, so every host
gets a display manager whether a profile asked for one or not.

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
