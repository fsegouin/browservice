# Browservice in Docker

Runs the final official Browservice release (v0.9.12.2) in a container, for
use from vintage browsers such as Safari 3 on Mac OS X 10.4.

**Browservice is unmaintained and its bundled Chromium no longer receives
security updates.** Use it for light browsing only, keep it off untrusted
networks, and avoid signing in to important accounts through it.

## Files

- `Dockerfile` downloads the upstream AppImage, checks its SHA-256 and unpacks
  it (Docker has no FUSE) into a Debian image that runs it as an unprivileged
  user. It also patches the client page so old Safari gets mouse wheel
  scrolling (see below).
- `browservice-seccomp.json` is Docker's default seccomp profile plus rules
  allowing `clone` and `unshare` with only the namespace flags Chromium's
  sandbox uses (user, PID and network), so the sandbox can run without giving
  the container `CAP_SYS_ADMIN` or disabling seccomp.
- `start-browservice.sh` rebuilds the image (quick once cached) and starts the
  container with that profile and `no-new-privileges`, bound to `127.0.0.1`
  only.

## Usage

```sh
sh docker/start-browservice.sh            # open http://127.0.0.1:18080/ locally
sh docker/start-browservice.sh oldmac     # reach it from host "oldmac" over SSH
```

With an SSH host, the script opens a reverse tunnel so the client machine
opens `http://127.0.0.1:8080/`. Browservice itself has no encryption, and this
setup does not turn on its optional HTTP basic auth (`--vice-opt-http-auth`),
so anything that can reach the port can use the browser. The tunnel encrypts
the traffic and keeps the port on the loopback interface of both machines, but
any local user or program on either machine can still connect, and a client
sshd with `GatewayPorts yes` opens the port to its network. The client needs
an SSH server (on Mac OS X: Remote Login), and a modern OpenSSH client may
need `HostKeyAlgorithms +ssh-rsa` for very old servers; set it for that host
only.

## Changes from upstream behaviour

- **Mouse wheel on old Safari.** The client page only used `onmousewheel` for
  Chrome and IE and fell back to `onwheel`, which Safari 3-5 lack. The source
  fix in `viceplugins/retrojsvice/html/main.html` falls back to
  `onmousewheel` when `onwheel` is unsupported. Because the image uses the
  prebuilt release, the Dockerfile applies an equivalent same-length patch to
  `retrojsvice.so`, making old Safari take the `onmousewheel` path.
- **Navigation forwarding is off.** Its history tricks leave Safari 3 on a
  blank page; the control bar's own Back/Forward buttons are shown instead.
- **Start page** is DuckDuckGo rather than `about:blank`.
- Browsing runs in incognito mode: cookies and logins are discarded when the
  container stops.

The Verdana font for the control bar is not installed, because doing so means
accepting Microsoft's EULA. If you accept it, add
`RUN /opt/bsv/browservice.AppDir/AppRun --install-verdana` after the
`USER bsv` line in the `Dockerfile`; the script rebuilds the image on its next
run.
