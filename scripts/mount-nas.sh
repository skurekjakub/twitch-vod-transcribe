#!/bin/bash
set -e

# Mount NAS (/nas)
#
# Usage: vod mount-nas
#
# Mounts /nas using CIFS credentials from .env.local.

# Get the root directory (parent of scripts/) - can be overridden for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${VOD_ROOT_DIR:-$(dirname "$SCRIPT_DIR")}"
cd "$ROOT_DIR"

MOUNTS_FILE="${PROC_MOUNTS_FILE:-/proc/mounts}"
ENV_FILE="${ROOT_DIR}/.env.local"

show_help() {
  cat << 'EOF'
Mount NAS

Usage: vod mount-nas

Mounts /nas using CIFS credentials from .env.local.

Options:
  -h, --help      Show this help message

Required environment variables (in .env.local):
  NAS_HOST        Hostname or IP of NAS server
  NAS_SHARE       Share name on NAS server
  NAS_USER        Username for authentication (optional, uses guest if not provided)
  NAS_PASS        Password for authentication (optional, uses guest if not provided)

Example .env.local:
  NAS_HOST=192.168.1.100
  NAS_SHARE=media
  NAS_USER=myuser
  NAS_PASS=mypassword

Notes:
  - Requires root privileges (try: sudo ./vod mount-nas)
  - Creates /nas directory if it doesn't exist
  - Uses CIFS protocol with SMB 3.0
EOF
}

# Parse arguments
if [[ $# -gt 0 ]]; then
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1"
      echo "Usage: vod mount-nas"
      exit 1
      ;;
  esac
fi

# Load credentials from .env.local
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env.local not found at: $ENV_FILE"
  echo "Create .env.local with NAS credentials (see --help for format)"
  exit 1
fi

echo "Loading NAS credentials from .env.local..."
# shellcheck disable=SC1090
source <(grep -v '^#' "$ENV_FILE" | grep -E '^(NAS_HOST|NAS_SHARE|NAS_USER|NAS_PASS)=' || true)

# Check required variables
if [[ -z "$NAS_HOST" ]] || [[ -z "$NAS_SHARE" ]]; then
  echo "Error: NAS_HOST and NAS_SHARE must be defined in .env.local"
  echo "See 'vod mount-nas --help' for configuration details"
  exit 1
fi

# Check if already mounted
if [[ ! -r "$MOUNTS_FILE" ]]; then
  echo "Error: Cannot read mounts file: $MOUNTS_FILE"
  exit 1
fi

if grep -qs " /nas " "$MOUNTS_FILE"; then
  echo "NAS is already mounted at /nas"
  exit 0
fi

# Create mount point if it doesn't exist
if [[ ! -d "/nas" ]]; then
  echo "Creating /nas directory..."
  mkdir -p /nas
fi

# Build mount options
MOUNT_OPTS="vers=3.0"
if [[ -n "$NAS_USER" ]] && [[ -n "$NAS_PASS" ]]; then
  MOUNT_OPTS="${MOUNT_OPTS},username=${NAS_USER},password=${NAS_PASS}"
else
  echo "Warning: NAS_USER or NAS_PASS not set, using guest access"
  MOUNT_OPTS="${MOUNT_OPTS},guest"
fi

# Mount the NAS
echo "Mounting NAS at /nas..."
echo "  Host: //${NAS_HOST}/${NAS_SHARE}"
echo "  Options: ${MOUNT_OPTS/password=*/password=***}"

# Use mount from PATH (mockable in tests)
if ! command -v mount >/dev/null 2>&1; then
  echo "Error: mount command not found"
  exit 1
fi

if mount -t cifs "//${NAS_HOST}/${NAS_SHARE}" /nas -o "${MOUNT_OPTS}"; then
  echo "NAS mounted successfully at /nas"
else
  echo "Error: Failed to mount NAS"
  exit 1
fi
