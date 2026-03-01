# proot-compat

LD_PRELOAD shim that fixes three compatibility issues when running **dropbear** and **tmux** inside a PRoot environment as a non-root user (e.g. Termux `proot-distro` with `--user`).

## Problems solved

### 1. dropbear: "Broken pipe" on interactive SSH sessions

dropbear calls `chown(/dev/pts/N, uid, tty_gid)` to transfer PTY ownership after allocating it. PRoot only fakes `chown` for the root user — non-root processes get `EPERM`, which dropbear treats as a fatal error and closes the connection.

**Fix:** intercept `chown`/`fchown`/`chmod` on `/dev/pts/*` paths and return success silently.

### 2. tmux: "access not allowed" when attaching to a session

tmux authenticates clients by calling `getsockopt(SO_PEERCRED)` on the socket and comparing the peer uid against its own `getuid()`. Inside PRoot with `--change-id`, `getuid()` returns the faked uid (e.g. `10351`), but `SO_PEERCRED` returns the real kernel uid (e.g. `10350`). The mismatch causes every attach attempt to be rejected.

**Fix:** intercept `getsockopt(SO_PEERCRED)` and replace `cred->uid`/`cred->gid` with the values from `getuid()`/`getgid()`.

### 3. tmux: default socket created with mode 0660

PRoot ignores the process umask when `bind()` creates an AF_UNIX socket, producing mode `0660` (group-readable). tmux refuses to use a socket with group or other bits set.

**Fix:** intercept `bind()` and immediately `chmod` the socket to `0600` for any path under `/tmp/tmux-*`.

## Build

```sh
make
```

Produces `libfakechown.so`. Requires `gcc` and `libdl`.

## Install

```sh
make install
```

Copies `libfakechown.so` to `/home/akulov/libfakechown.so` and installs `tmux-wrapper.sh` as `/usr/local/bin/tmux`.

Or manually:

```sh
# dropbear — in your startup script or /etc/dropbear/run:
exec env LD_PRELOAD=/home/akulov/libfakechown.so dropbear -R -p 1322

# tmux — wrapper at /usr/local/bin/tmux (before /usr/bin/tmux in PATH):
#!/bin/sh
umask 0077
exec env LD_PRELOAD=/home/akulov/libfakechown.so /usr/bin/tmux "$@"
```

## Context

Tested on Termux with `proot-distro` (Ubuntu), PRoot kernel `6.17`, dropbear `2022.83`, tmux `3.x`. The real kernel uid and the PRoot-faked uid differ by one because `proot-distro --user` maps the Termux uid to a different value inside the chroot.
