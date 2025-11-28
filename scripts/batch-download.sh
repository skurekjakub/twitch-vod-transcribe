#!/bin/bash
set -e

# Batch Video Downloader
# Downloads multiple videos from a URL file
#
# Usage: vod batch download [OPTIONS] [url_file]
# 
# Examples:
#   vod batch download urls-vods
#   vod batch download --continue-on-error urls-vods
#
# URL file format (one URL per line):
#   https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   https://youtu.be/jNQXAC9IVRw
#   https://www.twitch.tv/videos/2588036186
#
# Blank lines and lines starting with # are ignored
#
# Dependencies: yt-dlp

# Get the root directory (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Default values
URL_FILE="urls-vods"
CONTINUE_ON_ERROR=false

# Parse arguments
positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'EOF'
Batch Video Downloader

Usage: vod batch download [OPTIONS] [url_file]

Downloads multiple videos from a URL file. Processes completed URLs by
moving them to <url_file>-processed.

Options:
  --continue-on-error     Continue processing remaining URLs if one fails
  -h, --help              Show this help message

Arguments:
  url_file                File containing URLs (default: urls-vods)

URL file format:
  https://www.youtube.com/watch?v=dQw4w9WgXcQ
  https://youtu.be/jNQXAC9IVRw my-prefix
  # Comments start with #
  
Examples:
  vod batch download                           # Process urls-vods
  vod batch download my-urls.txt               # Custom file
  vod batch download --continue-on-error       # Don't stop on failure
EOF
      exit 0
      ;;
    --continue-on-error)
      CONTINUE_ON_ERROR=true
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1"
      echo "Usage: vod batch download [OPTIONS] [url_file]"
      exit 1
      ;;
    *)
      positional_args+=("$1")
      shift
      ;;
  esac
done

# Set URL file from positional arg or use default
if [ ${#positional_args[@]} -gt 0 ]; then
  URL_FILE="${positional_args[0]}"
fi

# Validate URL file exists
if [ ! -f "$URL_FILE" ]; then
  echo "Error: URL file not found: $URL_FILE"
  echo "Usage: vod batch download [OPTIONS] [url_file]"
  echo "Default file: urls-vods"
  exit 1
fi

# Create directories
mkdir -p logs

# Generate log file
timestamp=$(date +%Y.%m.%d-%H:%M:%S)
log_file="logs/batch-download-${timestamp}.log"
ID="BATCH-DL"

# Processed URLs file
PROCESSED_FILE="${URL_FILE}-processed"

# Function to log messages
log() {
  echo "$ID - $(date +%Y.%m.%d-%H:%M:%S) - $1" | tee -a "$log_file"
}

# Function to move a processed line from URL_FILE to PROCESSED_FILE (prepend)
mark_processed() {
  local line_to_remove="$1"
  local video_title="$2"
  # Prepend the line to processed file with timestamp and title (newest at top)
  local temp_file="${PROCESSED_FILE}.tmp"
  {
    echo "# Processed: $(date +%Y-%m-%d\ %H:%M:%S) - $video_title"
    echo "$line_to_remove"
    [ -f "$PROCESSED_FILE" ] && cat "$PROCESSED_FILE"
  } > "$temp_file"
  mv "$temp_file" "$PROCESSED_FILE"
  # Remove the line from the URL file (using a temp file for safety)
  grep -vFx "$line_to_remove" "$URL_FILE" > "${URL_FILE}.tmp" || true
  mv "${URL_FILE}.tmp" "$URL_FILE"
}

# Start processing
log "Starting batch video download from: $URL_FILE"

# Check for NAS
if grep -qs " /nas " /proc/mounts; then
  log "NAS detected. Videos will be downloaded to /nas/vods/<channel_name>"
else
  log "NAS not detected. Videos will be downloaded to local 'videos/' directory"
fi

# Count total URLs (excluding blank lines and comments)
total_urls=$(grep -v '^[[:space:]]*$' "$URL_FILE" | grep -v '^[[:space:]]*#' | wc -l)
log "Found $total_urls URLs to process"

# Initialize counters
processed=0
successful=0
failed=0
skipped=0

# Store lines in array first (so we can modify the file while iterating)
mapfile -t lines < "$URL_FILE"

# Process each line
for line in "${lines[@]}"; do
  # Skip blank lines and comments
  if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
    continue
  fi
  
  # Parse URL and optional prefix
  read -r url prefix <<< "$(echo "$line" | xargs)"
  
  processed=$((processed + 1))
  log ""
  log "[$processed/$total_urls] Processing: $url"
  if [ -n "$prefix" ]; then
    log "Prefix: $prefix"
  fi
  
  # Validate URL format (basic check)
  if [[ ! "$url" =~ ^https?:// ]]; then
    log "⚠ Invalid URL format, skipping: $url"
    skipped=$((skipped + 1))
    continue
  fi
  
  # Download video using the download script, capture output to extract title
  video_title=""
  if [ "$CONTINUE_ON_ERROR" = true ]; then
    download_output=$( "${SCRIPT_DIR}/download.sh" "$url" "$prefix" 2>&1 | tee /dev/stderr ) || download_failed=true
    video_title=$(echo "$download_output" | grep -oP 'Video: \K.*' | head -1)
    if [ "${download_failed:-false}" = false ]; then
      successful=$((successful + 1))
      log "✓ Successfully downloaded video"
      mark_processed "$line" "$video_title"
      log "→ Moved to $PROCESSED_FILE"
    else
      failed=$((failed + 1))
      log "✗ Failed to download video (continuing, keeping in queue)"
    fi
    download_failed=false
  else
    download_exit_code=0
    download_output=$( "${SCRIPT_DIR}/download.sh" "$url" "$prefix" 2>&1 | tee /dev/stderr ) || download_exit_code=$?
    video_title=$(echo "$download_output" | grep -oP 'Video: \K.*' | head -1)
    if [ "$download_exit_code" -eq 0 ]; then
      successful=$((successful + 1))
      log "✓ Successfully downloaded video"
      mark_processed "$line" "$video_title"
      log "→ Moved to $PROCESSED_FILE"
    else
      failed=$((failed + 1))
      log "✗ Failed to download video (exit code: $download_exit_code)"
      exit 1
    fi
  fi
  
done

# Summary
log ""
log "========================================"
log "Batch download complete!"
log "Total URLs: $total_urls"
log "Successful: $successful"
log "Failed: $failed"
log "Skipped: $skipped"
log "Log file: $log_file"
log "========================================"

# Exit with error if any failed (unless continue-on-error)
if [ "$failed" -gt 0 ] && [ "$CONTINUE_ON_ERROR" = false ]; then
  exit 1
fi

exit 0
