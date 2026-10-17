# nixos-conf

NixOS configuration for all my machines. One directory per host under `hosts/`,
shared behaviour in opt-in modules under `modules/`.

The repo is checked out at `~/nixos-conf`, with no symlink indirection.

Further docs:

- [docs/reference.md](docs/reference.md) for layout, profiles and the VM,
  dev-shell and dotfile workflows
- [docs/vm-workflow.md](docs/vm-workflow.md) for writing a host before the
  machine exists
- [docs/options.md](docs/options.md) for what each `my.*` option does
- [docs/secrets.md](docs/secrets.md) for sops, the age keys and what must
  be in 1Password
- [docs/backups.md](docs/backups.md) for restic and restoring data

## Rebuild this machine

```sh
os-diff
```

That is the normal way. It builds, prints what would change, and asks before
switching -- answer no and the running system is untouched. It wraps
`nh os switch --ask --diff always` and finds the flake through `NH_FLAKE`.

Without the wrapper:

```sh
sudo nixos-rebuild switch --flake ~/nixos-conf
```

On a host with no checkout, build from the pushed flake instead. This is how
cortex is deployed: edit and push from another machine, then ssh in and run

```sh
sudo nixos-rebuild switch --flake github:jerhage/nixos-conf#cortex --refresh
```

`--refresh` is not optional. A `github:` reference is mutable and nix caches it
for an hour, so without it the build can quietly use the previous commit. The
upside of this route is that whatever is running is always a pushed hash.

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
5. `git add hosts/<hostname>`, because flakes ignore untracked files.
6. `sudo nixos-rebuild switch --flake ~/nixos-conf#<hostname>`
   (the `#<hostname>` is only needed this first time, before the hostname is set)

The host directory name _is_ the hostname; `flake.nix` contains no hostnames.

### Steps the config cannot do for you

A rebuilt host needs two things by hand. Neither is in the flake.

- `sudo tailscale up` joins the tailnet. Identity lives in
  `/var/lib/tailscale`. Until this runs, `tailscale-serve.service` retries and
  fails, so services are unreachable even though everything else is up.
- Restoring data: service state and anything under `/var/lib` the config does
  not generate. It sets ownership and permissions, but the files themselves have
  to come from a backup. On a host with `my.backup`:
  `restic-local restore latest --target /`.

`tailscale serve` used to be a third. `my.server.tailscaleServe` now does it,
because a reinstall dropped it silently and nothing pointed at the cause.
