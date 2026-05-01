#!/usr/bin/env bash
# entrypoint.sh — Handles UID/GID mapping for bind-mounted volumes
#
# This script adjusts the 'pulper' user to match the host's UID/GID 
# (detected from the /output volume) and then drops privileges.

set -euo pipefail

# BAIL FAST: If we are already non-root, we can't (and don't need to) 
# do any of the user/group modification logic. Just exec the command.
if [ "$(id -u)" != "0" ]; then
    exec "$@"
fi

# ---------------------------------------------------------------------------
# If we reached here, we are running as ROOT. 
# ---------------------------------------------------------------------------

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
exec gosu pulper "$@"
