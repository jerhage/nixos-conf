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

`nixos-rebuild` picks the host matching the current hostname, so no `#name` is
needed. To check without activating anything:

```sh
nixos-rebuild build --flake ~/nixos-conf        # builds ./result, activates nothing
nixos-rebuild dry-activate --flake ~/nixos-conf # shows which units a switch would touch
```

`build` leaves a `result` symlink, which Nix registers as a GC root -- it will
pin that whole system closure until removed. `rm -f result` when done, or use
`--no-link`.

## Rebuild another host

Build here and copy the result over, rather than making the target build it:

```sh
cd ~/nixos-conf
nixos-rebuild switch --flake .#cortex --target-host cortex --sudo --ask-sudo-password
```

Run it as your own user, not under sudo, since it needs your ssh keys. It
deploys the working tree, so nothing has to be committed first.

This requires the target to trust you as a pusher. Without
`nix.settings.trusted-users` including your user there, it fails with:

```
error: cannot add path '/nix/store/...' because it lacks a signature by a trusted key
```

`modules/nix.nix` sets that for every host, so a host built from this repo
already allows it. See [docs/options.md](docs/options.md#trusted-users) for
what being trusted grants.

### When there is no path from here

Build on the target from the pushed flake:

```sh
sudo nixos-rebuild switch --flake github:jerhage/nixos-conf#cortex --refresh
```

`--refresh` is not optional. A `github:` reference is mutable and nix caches it
for an hour, so without it the build can quietly use the previous commit. This
route needs the change committed and pushed, and it makes the target build its
own closure, but what is running is always an identifiable pushed hash. It is
also the only route into a host that does not trust you yet, which is how
cortex was first brought up.

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
