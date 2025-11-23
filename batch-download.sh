#!/bin/bash
set -e

# Batch Video Downloader
# Downloads multiple videos from a URL file using direct-video.sh
#
# Usage: ./batch-download.sh [OPTIONS] [url_file]
# 
# Examples:
#   ./batch-download.sh urls-vods
#   ./batch-download.sh --continue-on-error urls-vods
#
# URL file format (one URL per line):
#   https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   https://youtu.be/jNQXAC9IVRw
#   https://www.twitch.tv/videos/2588036186
#
# Blank lines and lines starting with # are ignored
#
# Options:
#   --continue-on-error     Continue processing remaining URLs if one fails
#
# Dependencies: yt-dlp

cd "$(dirname "$0")"

# Default values
URL_FILE="urls-vods"
CONTINUE_ON_ERROR=false

# Parse arguments
positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --continue-on-error)
      CONTINUE_ON_ERROR=true
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1"
      echo "Usage: $0 [OPTIONS] [url_file]"
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
  echo "Usage: $0 [OPTIONS] [url_file]"
  echo "Default file: urls-vods"
  echo "Example: $0 urls-vods"
  exit 1
fi

# Create directories
mkdir -p logs

# Generate log file
timestamp=$(date +%Y.%m.%d-%H:%M:%S)
log_file="logs/batch-download-${timestamp}.log"
ID="BATCH-DL"

# Function to log messages
log() {
  echo "$ID - $(date +%Y.%m.%d-%H:%M:%S) - $1" | tee -a "$log_file"
}

# Start processing
log "Starting batch video download from: $URL_FILE"

# Count total URLs (excluding blank lines and comments)
total_urls=$(grep -v '^[[:space:]]*$' "$URL_FILE" | grep -v '^[[:space:]]*#' | wc -l)
log "Found $total_urls URLs to process"

# Initialize counters
processed=0
successful=0
failed=0
skipped=0

# Read URLs line by line
while IFS= read -r line || [ -n "$line" ]; do
  # Skip blank lines and comments
  if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
    continue
  fi
  
  # Trim whitespace
  url=$(echo "$line" | xargs)
  
  processed=$((processed + 1))
  log ""
  log "[$processed/$total_urls] Processing: $url"
  
  # Validate URL format (basic check)
  if [[ ! "$url" =~ ^https?:// ]]; then
    log "⚠ Invalid URL format, skipping: $url"
    skipped=$((skipped + 1))
    continue
  fi
  
  # Download video
  if [ "$CONTINUE_ON_ERROR" = true ]; then
    if ./direct-video.sh "$url"; then
      successful=$((successful + 1))
      log "✓ Successfully downloaded video"
    else
      failed=$((failed + 1))
      log "✗ Failed to download video (continuing)"
    fi
  else
    ./direct-video.sh "$url"
    successful=$((successful + 1))
    log "✓ Successfully downloaded video"
  fi
  
done < "$URL_FILE"

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
