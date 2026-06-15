#!/usr/bin/env bash
set -euo pipefail

# Resolve PUID/PGID — support both Unraid-style and upstream env vars.
PUID=${PUID:-${HERMES_UID:-1000}}
PGID=${PGID:-${HERMES_GID:-1000}}

# Validate numeric
if ! [[ "$PUID" =~ ^[0-9]+$ ]] || ! [[ "$PGID" =~ ^[0-9]+$ ]]; then
  echo "ERROR: PUID and PGID must be numeric (got PUID=$PUID PGID=$PGID)" >&2
  exit 1
fi

# Remap hermes user/group to target UID:GID
groupmod -o -g "$PGID" hermes
usermod  -o -u "$PUID" hermes

# Own the data directory
chown -R hermes:hermes /opt/data

# Drop privileges and exec
exec gosu hermes hermes "$@"
