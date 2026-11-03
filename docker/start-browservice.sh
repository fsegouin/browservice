#!/bin/sh
# Start Browservice in Docker, listening on this machine's localhost only.
#
#   sh start-browservice.sh [ssh-host]
#
# With an SSH host (any name ssh understands, e.g. an alias from ~/.ssh/config),
# port 8080 on that host is forwarded back to Browservice, so the old machine
# opens http://127.0.0.1:8080/ and the traffic travels inside SSH.
# Without one, open http://127.0.0.1:18080/ on this machine.
# Control-C stops everything.
CDPATH='' cd -- "$(dirname -- "$0")" || exit 1

IMAGE=browservice:0.9.12.2
# Rebuild every time so Dockerfile changes are picked up; cached layers make it quick.
docker build -q -t "$IMAGE" . >/dev/null || exit 1

# Clear the previous run's container (kept after stopping so its logs can be read).
docker rm -f browservice >/dev/null 2>&1
# Stop the container on any exit. The signal traps only exit, so the EXIT trap
# runs once and the exit status reports the signal.
trap 'docker stop browservice >/dev/null 2>&1' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
docker run -d --name browservice \
    --shm-size=1g \
    --security-opt no-new-privileges \
    --security-opt seccomp="$PWD/browservice-seccomp.json" \
    -p 127.0.0.1:18080:8080 \
    "$IMAGE" >/dev/null || exit 1

echo "Press Control-C to stop."
if [ -n "$1" ]; then
    echo "Browservice running. On $1, open http://127.0.0.1:8080/"
    ssh -N -o ExitOnForwardFailure=yes -R 8080:127.0.0.1:18080 -- "$1"
else
    echo "Browservice running at http://127.0.0.1:18080/"
    docker wait browservice >/dev/null
fi
