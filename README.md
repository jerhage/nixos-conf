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
| `modules/profiles.nix` | Bundles modules for a kind of machine (`my.profiles.workstation`). |
| `modules/home/` | home-manager modules, wired to `my.user` by `modules/home-manager.nix`. |
| `hosts/<name>/` | Per-machine config and its `hardware-configuration.nix`. |
| `templates/host/` | Starting point for a new host. |

Always on regardless of profile: `nix.nix`, `user.nix`, `git.nix`,
`home-manager.nix`, `profiles.nix`.

## Dotfiles

Application configs are managed in a separate dotfiles repo in each
application's native format. home-manager points at them with
`mkOutOfStoreSymlink`, so edits there take effect without a rebuild.
