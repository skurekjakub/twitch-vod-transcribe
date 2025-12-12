#!/bin/bash
set -e

# Unmount NAS (/nas)
#
# Usage: vod unmount-nas
#
# Safely unmounts /nas if it is currently mounted.

# Get the root directory (parent of scripts/) - can be overridden for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${VOD_ROOT_DIR:-$(dirname "$SCRIPT_DIR")}"
cd "$ROOT_DIR"

MOUNTS_FILE="${PROC_MOUNTS_FILE:-/proc/mounts}"

show_help() {
  cat << 'EOF'
Unmount NAS

Usage: vod unmount-nas

Unmounts /nas if it is currently mounted.

Options:
  -h, --help      Show this help message

Notes:
  - May require root privileges (try: sudo ./vod unmount-nas)
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
      echo "Usage: vod unmount-nas"
      exit 1
      ;;
  esac
fi

if [[ ! -r "$MOUNTS_FILE" ]]; then
  echo "Error: Cannot read mounts file: $MOUNTS_FILE"
  exit 1
fi

if ! grep -qs " /nas " "$MOUNTS_FILE"; then
  echo "NAS is not mounted (/nas)"
  exit 0
fi

echo "Unmounting /nas..."

# Use umount from PATH (mockable in tests)
if ! command -v umount >/dev/null 2>&1; then
  echo "Error: umount command not found"
  exit 1
fi

umount /nas

echo "NAS unmounted (/nas)"
