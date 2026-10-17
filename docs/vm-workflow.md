# Developing a host in a VM

`nixos-rebuild build-vm` boots a host directory as a QEMU guest. A host can
therefore be written, reviewed and largely finished before the machine it
describes exists. cortex was built this way: by the time the hardware was
installed, the services, reverse proxy and backup definitions were already
written and had been running in a guest.

This is the long version of the short section in
[reference.md](reference.md#trying-a-host-config-in-a-vm).

## Why even do this

Three things, roughly in order of value.

**Fast iteration on option shapes.** Most of the work in adding a host is not
the host file, it is the modules it needs. `my.server`, `my.ankiSync` and
`my.backup` were all designed against a guest, where a bad option name costs a
rebuild and a reboot rather than a trip to another room.

**Pressure on the shared modules.** Booting a headless host exposed everything
in `base` that silently assumed a desktop. That is how `my.i18n` ended up split
into `my.i18n.enable` for locales, which any host needs to handle CJK
filenames, and `my.i18n.inputMethod.enable` for fcitx5, which needs a graphical
session. Without a headless guest to boot, that would have been found on the
real machine instead.

**A reviewable config before committing to hardware.** The host file, the Caddy
routing and the service hardening were all settled while the machine was still
running Proxmox.

## How the VM variant is set up

`modules/vm.nix` defines `virtualisation.vmVariant`, which NixOS applies only
to `build-vm` and ignores on a real switch. It sets 4 GB of RAM, 4 cores and an
8 GB disk, and gives the user `initialPassword = "nixos"` so there is a way in.

Two options control the awkward parts:

`my.vm.graphics` opens a QEMU window. Off by default, because a host configured
for a real GPU rarely boots graphically under emulation. With it off the guest
runs on the console in the terminal and `poweroff` exits.

`my.vm.shareDotfiles` mounts the dotfiles repo into the guest over 9p at the
same path, so `my.dotfiles.links` resolves to the same files the host is
editing. With it off, the links are force-disabled instead, because without the
repo every symlink dangles and tmpfiles logs a failure for each one.

## The loop

```sh
nixos-rebuild build-vm --flake ~/nixos-conf#<hostname>
./result/bin/run-<hostname>-vm
```

Inside the guest, the usual tools work for checking what the config produced:

```sh
systemctl --failed
systemctl cat <service>                 # the generated unit, including hardening
systemd-analyze security <service>      # exposure score
curl -sI http://127.0.0.1/<site>/       # Caddy routing, before tailscale exists
journalctl -u <service> -b --no-pager
```

The guest gets a fresh disk each build, so state is not carried between
iterations. That is usually what you want when checking first-boot behaviour,
and is why seeding real data is pointless here.

Each `build-vm` leaves a `result` symlink, which Nix treats as a GC root and
which pins the whole guest closure. `rm -f result` when finished.

## Starting a host before the machine exists

cortex was scaffolded from `templates/host` with two deliberate placeholders:

`hardware-configuration.nix` was a stub, replaced later by
`nixos-generate-config` output from the real machine. The VM supplies its own
disk and bootloader config, so the stub does not matter until install day.

`my.secrets.enable` stayed `false`. sops derives the host's age key from its ssh
host key, and a guest's key is regenerated every boot, so there is nothing
stable to add to `.sops.yaml`. Anything secret-dependent is therefore untestable
in a VM by construction.

## Limits of the VM

Some times it looks like things are working, but they are masked and still break on real hardware.

**Permissions on data that arrives from somewhere else.** The calibre library
came out of an rclone remote as `0644/0755`, so the `calibre-web` group could
read `metadata.db` but not write it, and calibre's backend runs schema
statements on open. It surfaced as `apsw.ReadOnlyError` and a 404 on every
download, never as a permission error. The fix was a POSIX ACL rather than a
mode. A guest with an empty library cannot produce this.

**Service state that is not where the path says.** `my.backup` listed
`/var/lib/anki-sync-server`, which is a symlink into `/var/lib/private` because
the service runs with `DynamicUser`. restic does not follow symlinks. The first
snapshot exited cleanly, reported 20.8 GiB and listed every path while
containing none of the anki data. Only a restore caught it. The module now
resolves paths with `readlink -f` at backup time.

**Sandboxing against real workloads.** The nixpkgs calibre-web module denies
`@resources` in its `SystemCallFilter`, which kills `setpriority` with SIGSYS,
which kills every converter calibre-web starts. Nothing reveals this until a
conversion is attempted against a real book.

**Anything keyed to host identity**, per the sops note above, plus disk layout,
firmware and real network interfaces. The host's `my.ssh.server.interfaces`
names `eno1`, which only means something on the actual board.

## Moving to hardware

Every command below says which machine it runs on. The repo lives on nucleus;
cortex has no checkout and deploys from the pushed flake, which is what makes
the ordering matter.

**1. Install NixOS. (cortex)**

From a USB installer, with any minimal configuration. The disk had Proxmox on
it, and the install kept failing with a UEFI error until the disk was
repartitioned with an EFI system partition.

**2. Generate the hardware config. (cortex)**

```sh
sudo nixos-generate-config --show-hardware-config > /tmp/hardware-configuration.nix
```

`--show-hardware-config` prints to stdout and writes nothing under `/etc`, so
this cannot disturb the machine's own configuration.

**3. Move it into the host directory. (nucleus)**

```sh
scp cortex:/tmp/hardware-configuration.nix ~/nixos-conf/hosts/cortex/hardware-configuration.nix
```

This replaces the stub copied from `templates/host`. It needs sshd and your key
already present on the minimal install; if they are not, move the file any
other way, the content is all that matters. The generated file is what pins the
filesystem UUIDs, the bootloader and the initrd modules, which is why none of
it could be written by hand in advance.

**4. Commit and push. (nucleus)**

```sh
git add hosts/cortex/hardware-configuration.nix
git commit && git push
```

Both halves are required: flakes ignore untracked files, and cortex builds from
the pushed commit rather than the working tree.

**5. First switch from the pushed flake. (cortex)**

```sh
sudo nixos-rebuild switch --flake github:jerhage/nixos-conf#cortex --refresh
```

`my.secrets.enable` is still `false` at this point, so nothing here needs a
decryption key.

**6. Read the new host key. (cortex)**

```sh
cat /etc/ssh/ssh_host_ed25519_key.pub
```

sshd creates this on first boot and it is stable from then on, which is exactly
what a VM could not provide.

**7. Convert it to an age key. (nucleus)**

```sh
ssh-to-age < cortex-host-key.pub
```

Run it on nucleus rather than cortex: `ssh-to-age` ships with
`my.secrets.enable`, which cortex does not have on yet. `, ssh-to-age` works
anywhere if you would rather not copy the file.

**8. Add the key as a recipient and re-encrypt. (nucleus)**

Add the age key to `.sops.yaml` under `keys` as `&cortex`, then reference that
anchor in the `creation_rules` entry for `secrets/secrets.yaml`. Then:

```sh
sops updatekeys secrets/secrets.yaml
```

This has to run on a host that can already decrypt the file. Editing
`.sops.yaml` alone changes nothing about the existing ciphertext: without
`updatekeys` the file stays encrypted to the old recipients only, and cortex
fails to decrypt with no indication that the recipient list is the reason.

**9. Turn secrets on, then push and switch again. (nucleus, then cortex)**

Set `my.secrets.enable = true` in `hosts/cortex/default.nix`, commit, push, and
on cortex:

```sh
sudo nixos-rebuild switch --flake github:jerhage/nixos-conf#cortex --refresh
sudo cat /run/secrets/test
```

The second command is the end-to-end check that the key, the recipient list and
the re-encryption all line up.

**10. Join the tailnet. (cortex)**

```sh
sudo tailscale up
```

Until this runs, `tailscale-serve.service` retries and fails, so the services
are unreachable even though they are running.

**11. Seed the data. (cortex)**

```sh
pull-calibre-cloud
```

This depends on `/run/secrets/rclone-conf`, so it only works after step 9. The
20.8 GiB already in Dropbox was the transport, rather than copying over the LAN.

Steps 6 through 9 are the ones a VM cannot rehearse, since they all hang off a
host key that only exists once the real machine has booted.
