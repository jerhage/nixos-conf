# Secrets

sops-nix, enabled per host with `my.secrets.enable`. Encrypted values live in
`secrets/secrets.yaml`, committed to this repo. Who may decrypt it is listed in
`.sops.yaml`, also committed. Both are safe to commit: the ciphertext is useless
without a private key, and `.sops.yaml` holds public keys only.

Every command below says which machine it runs on, because several of them only
work on a host that can already decrypt.

## The keys

Two kinds, and the difference decides what has to be backed up.

**Your personal age key.** Generated once, lives at
`~/.config/sops/age/keys.txt`, never committed. It is the `&jh` recipient in
`.sops.yaml`. This is the only key in the system that is not reproducible from
a machine, so it is the only one that must be backed up.

```sh
age-keygen -o ~/.config/sops/age/keys.txt    # once, ever
age-keygen -y ~/.config/sops/age/keys.txt    # print the public half
```

**Each host's key, derived from its ssh host key.** `modules/secrets.nix` sets
`age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]`, so a host decrypts
with a key computed from an identity it already has. Nothing to generate,
nothing to copy onto the machine, nothing to back up. The trade is that
reinstalling a host changes its key and the secrets file has to be re-encrypted
for the new one.

Note what "nothing to back up" does not mean: the public half of every host key
is in `.sops.yaml`, in the repo, in git history. What is not stored anywhere is
the private half, which stays in `/etc/ssh` on the machine.

## What has to be in 1Password

Three things. Losing any of them means losing access to data, not just
convenience.

**`~/.config/sops/age/keys.txt`**, the personal age key. If every host is lost
at once and this key is gone, `secrets/secrets.yaml` is permanently unreadable
and so is everything encrypted with the values inside it. A single surviving
host also works as a recovery path, which is why both nucleus and cortex are
recipients, but a key in 1Password is the only route that survives all hosts
dying together.

**The restic repository password.** It is in sops as `restic-password`, which is
circular for disaster recovery: the snapshots are what you reach for after
losing a machine, and the password for them would be locked inside a file you
can no longer decrypt. It needs to exist outside sops.

**The rclone crypt password and salt.** The encrypted copy of the library in
Dropbox is readable only with these. They sit inside `rclone-conf` in sops, in
rclone's obscured form, which is reversible rather than hashed. Same circularity
as the restic password, same fix.

The pattern: anything that is itself the key to a separate encrypted store must
not live only in sops, because sops is what you lose first.

## Secrets in use

| Name              | Declared in            | Mode   | Owner      |
| ----------------- | ---------------------- | ------ | ---------- |
| `restic-password` | `modules/backup.nix`   | `0400` | root       |
| `rclone-conf`     | `modules/sync-cloud.nix` | `0400` | `my.user`  |
| `anki-sync-users` | `modules/anki-sync.nix`  | `0400` | root       |
| `test`            | `modules/secrets.nix`  | `0400` | root       |

`test` exists only to prove the pipeline end to end and can be deleted once the
others are in place.

A host decrypts only the secrets it declares. Enabling `my.secrets.enable`
alone decrypts nothing but `test`; a secret appears under `/run/secrets/<name>`
because a module asked for it.

## Adding or editing a secret

On a host that can already decrypt:

```sh
cd ~/nixos-conf
sops secrets/secrets.yaml
```

That decrypts into your editor, and re-encrypts on save for every recipient in
`.sops.yaml`. Never edit the file with a plain editor and never `git add` a
decrypted copy.

The file is flat YAML, one key per secret:

```yaml
restic-password: hunter2
rclone-conf: |
    [dropbox]
    type = dropbox
    ...
```

Adding the value is half the job. The other half is declaring it, or nothing
will be decrypted at runtime:

```nix
sops.secrets.my-new-secret = {
  mode = "0400";
  owner = config.my.user;   # omit for root-only
};
```

It then appears at `/run/secrets/my-new-secret`, on tmpfs, readable only as
declared. Reference that path in the service that needs it, never the value.

Two things that bite:

A service running as a dynamic or system user cannot read a root-owned secret.
Set `owner` to match whatever consumes it. `rclone-conf` is owned by `my.user`
because the sync aliases run as you.

Some programs want to rewrite their config file and cannot, because
`/run/secrets/*` is read-only. rclone does this and logs a failure about saving
the token; it is harmless, since the refresh token is what matters and is never
rewritten.

## Adding a new host

A new host cannot decrypt anything until its key is a recipient. The full
sequence, including the install steps around it, is in
[vm-workflow.md](vm-workflow.md#moving-to-hardware). The sops-specific part:

**1. Read the new host's public ssh key. (new host)**

```sh
cat /etc/ssh/ssh_host_ed25519_key.pub
```

sshd generates this on first boot. It must be the real machine: a VM
regenerates its key on every boot, so there is nothing stable to add.

**2. Convert it to an age key. (a host that already has sops)**

```sh
ssh-to-age < newhost-host-key.pub
```

`ssh-to-age` ships with `my.secrets.enable`, so run it on an existing host
rather than the new one, which does not have it yet. `, ssh-to-age` works
anywhere.

**3. Add it as a recipient. (nucleus)**

In `.sops.yaml`, add the key under `keys` with an anchor, and reference that
anchor in the `creation_rules` entry:

```yaml
keys:
  - &newhost age1...
creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *jh
          - *nucleus
          - *newhost
```

**4. Re-encrypt for the new recipient list. (a host that can decrypt)**

```sh
sops updatekeys secrets/secrets.yaml
```

This step is the one that gets skipped. Editing `.sops.yaml` does not touch
existing ciphertext, so without `updatekeys` the file stays encrypted to the old
recipients and the new host fails to decrypt with nothing pointing at the
recipient list as the cause.

**5. Commit both files, then enable it. (nucleus)**

`.sops.yaml` and `secrets/secrets.yaml` both changed. Commit them, set
`my.secrets.enable = true` on the new host, and switch.

**6. Verify. (new host)**

```sh
sudo cat /run/secrets/test
```

If that prints, the key, the recipient list and the re-encryption all agree.

## Reinstalling a host

Same as adding one. The old host key is gone, so its age key is wrong, and
`sops updatekeys` has to run again for the new one. Remove the stale anchor from
`.sops.yaml` at the same time, or the file stays encrypted to a key nobody holds.

## If you lose a host

One host lost, others alive: nothing is at risk. The secrets file is encrypted
to every recipient independently, so any surviving host or your personal key
decrypts it.

All hosts lost: the personal age key from 1Password is the only way back into
`secrets/secrets.yaml`, and the restic password and rclone crypt credentials
from 1Password are the only way into the backups and the Dropbox copy. That is
the case the three 1Password entries exist for.
