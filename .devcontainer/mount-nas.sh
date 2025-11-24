#!/bin/bash

# Load NAS credentials from .env.local if it exists
if [ -f /workspaces/twitch-vod-transcribe/.env.local ]; then
    echo "🔐 Loading NAS credentials from .env.local..."
    export $(grep -v '^#' /workspaces/twitch-vod-transcribe/.env.local | xargs)
fi

# Mount NAS if credentials available
if [ -n "$NAS_HOST" ] && [ -n "$NAS_SHARE" ]; then
    # Check if already mounted
    if grep -qs " /nas " /proc/mounts; then
        echo "✅ NAS already mounted at /nas"
        exit 0
    fi

    echo "🗄️  Mounting NAS..."
    mkdir -p /nas
    
    MOUNT_OPTS="vers=3.0"
    if [ -n "$NAS_USER" ] && [ -n "$NAS_PASS" ]; then
        MOUNT_OPTS="${MOUNT_OPTS},username=${NAS_USER},password=${NAS_PASS}"
    else
        MOUNT_OPTS="${MOUNT_OPTS},guest"
    fi
    
    if mount -t cifs "//${NAS_HOST}/${NAS_SHARE}" /nas -o "${MOUNT_OPTS}"; then
        echo "✅ NAS mounted at /nas"
    else
        echo "⚠️  Failed to mount NAS"
    fi
else
    echo "ℹ️  NAS_HOST or NAS_SHARE not defined, skipping NAS mount."
fi
