#!/bin/bash
set -euo pipefail

# Resolve UID/GID — support both Unraid-style PUID/PGID and upstream HERMES_UID/HERMES_GID
TARGET_UID="${PUID:-${HERMES_UID:-10000}}"
TARGET_GID="${PGID:-${HERMES_GID:-10000}}"

echo "[hermes-entrypoint] Starting as UID=${TARGET_UID} GID=${TARGET_GID}"

# Validate numeric
if ! [[ "$TARGET_UID" =~ ^[0-9]+$ ]] || ! [[ "$TARGET_GID" =~ ^[0-9]+$ ]]; then
    echo "[hermes-entrypoint] ERROR: PUID/PGID must be numeric integers" >&2
    exit 1
fi

# Adjust hermes user/group to match requested UID/GID
groupmod -o -g "$TARGET_GID" hermes 2>/dev/null || true
usermod -o -u "$TARGET_UID" hermes 2>/dev/null || true

# Ensure data volume exists and is owned correctly
mkdir -p /opt/data
chown -R "${TARGET_UID}:${TARGET_GID}" /opt/data

# Drop privileges and exec hermes
exec gosu hermes hermes "$@"
