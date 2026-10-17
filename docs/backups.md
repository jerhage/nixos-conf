# Backups

`my.backup` runs restic daily to `rclone:dropbox:restic`, keeping 7 daily, 4
weekly and 12 monthly snapshots. The repo is not inside the `crypt:` remote:
restic already encrypts contents, filenames and structure.

Snapshots are cheap because files are split into content-hashed chunks and
stored once. A snapshot is a tree of references, so an unchanged 20 GB costs
kilobytes. restic also skips _reading_ files whose size and mtime match the
previous snapshot -- change the path list and that parent match is lost, so the
next run re-reads everything even though it uploads almost nothing.

The `restic-local` wrapper carries the repository, password file and rclone
config, so none of that needs typing.

```sh
restic-local snapshots                    # list; note an ID
restic-local ls latest /var/lib/calibre   # browse a snapshot
restic-local diff <id1> <id2>             # what changed between two
```

Restoring:

```sh
# one file, to stdout
restic-local dump latest /var/lib/calibre/metadata.db > ./recovered.db

# a subtree, somewhere safe to inspect first
restic-local restore latest --target /tmp/check --include /var/lib/calibre

# everything, in place, after losing a disk
restic-local restore latest --target /
```

To hunt for something without knowing which snapshot has it, mount them all:

```sh
sudo mkdir -p /mnt/snaps
sudo restic-local mount /mnt/snaps     # /mnt/snaps/snapshots/<date>/...
```

Two things worth noting cause it messed me up:

- **A `DynamicUser` service keeps state in `/var/lib/private/<name>` and
  symlinks `/var/lib/<name>` to it.** restic does not follow symlinks. The
  module resolves paths with `readlink -f` at backup time, so the path
  works, but a snapshot will look complete while actually not having anything.
- **Verify with a restore, never a file count.** The first snapshot here exited
  cleanly, reported 20.8 GiB and listed every path, while containing none of
  the anki data.

The repo password lives in sops as `restic-password` and in 1Password. It has to
be in both: the snapshots are what you reach for after losing a machine, and a
password readable only from inside sops is a password you cannot get to. See
[secrets.md](secrets.md#what-has-to-be-in-1password).
