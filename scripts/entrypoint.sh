#!/usr/bin/env bash
# entrypoint.sh — Handles UID/GID mapping and hands off to the Go classifier
set -euo pipefail

# 1. Handle UID/GID mapping for bind-mounted volumes
# If running as root, we set up the 'pulper' user and drop privileges via gosu.
if [[ "$(id -u)" == "0" ]]; then
    USER_ID=${USER_ID:-1000}
    GROUP_ID=${GROUP_ID:-1000}

    if ! getent group pulper >/dev/null; then
        groupadd -g "$GROUP_ID" pulper
    fi

    if ! getent passwd pulper >/dev/null; then
        useradd -u "$USER_ID" -g "$GROUP_ID" -s /bin/bash -m pulper
    fi

    # Ensure /output is writable if it exists
    if [[ -d "/output" ]]; then
        chown -R pulper:pulper /output
    fi

    # Hand off to gosu to drop privileges and re-run this script as pulper
    exec gosu pulper "$0" "$@"
fi

# 2. Hand off to the Go classifier
# This handles the intelligent routing to MarkItDown.
exec classifier "$@"

