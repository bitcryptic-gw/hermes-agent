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

# For gateway run: require the env file to exist (secrets must not be in docker inspect)
if [ "${1:-}" = "gateway" ] && [ "${2:-}" = "run" ]; then
    ENV_FILE="/opt/data/.hermes/.env"
    if [ ! -f "$ENV_FILE" ]; then
        echo "[hermes-entrypoint] ERROR: ${ENV_FILE} not found." >&2
        echo "[hermes-entrypoint] Create it with your API keys before starting the gateway." >&2
        echo "[hermes-entrypoint] See docs/user-guide/docker.md for required keys." >&2
        exit 1
    fi
fi

# Drop privileges and exec hermes
exec gosu hermes hermes "$@"
