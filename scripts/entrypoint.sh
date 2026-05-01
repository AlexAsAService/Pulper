#!/usr/bin/env bash
# entrypoint.sh — Handles UID/GID mapping for bind-mounted volumes
#
# This script runs as root, adjusts the 'pulper' user to match the 
# host's UID/GID (detected from the /output volume), and then 
# drops privileges to run the actual command.

set -e

# If the /output volume is mounted, try to match its ownership
if [ -d "/output" ]; then
    HOST_UID=$(stat -c '%u' /output)
    HOST_GID=$(stat -c '%g' /output)

    # Only adjust if the host UID isn't 0 (root) and doesn't match current pulper
    if [ "$HOST_UID" != "0" ] && [ "$HOST_UID" != "$(id -u pulper)" ]; then
        echo "==> Adjusting 'pulper' user to match host UID:GID ($HOST_UID:$HOST_GID)"
        usermod -o -u "$HOST_UID" pulper
        groupmod -o -g "$HOST_GID" pulper
        # Ensure home dir and app dir are still owned by the new UID
        chown -R pulper:pulper /home/pulper /app
    fi
fi

# Use gosu to drop from root to pulper and exec the original command
# This ensures the process is PID 1 and signals are handled correctly
if [ "$(id -u)" = "0" ]; then
    exec gosu pulper "$@"
else
    # We are already non-root, just exec
    exec "$@"
fi
