#!/bin/bash

# List YouTube Channel Videos
# Lists all videos from a YouTube channel (excludes shorts)
#
# Usage: vod list-youtube <channel_url_or_handle> [options]
# 
# Examples:
#   vod list-youtube @MrBeast                    # List all videos
#   vod list-youtube @MrBeast --urls-only        # Just URLs
#   vod list-youtube @MrBeast --limit 10         # Last 10 videos
#   vod list-youtube https://www.youtube.com/@MrBeast
#
# Dependencies: yt-dlp

set -e

# Get the root directory (parent of scripts/) - can be overridden for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${VOD_ROOT_DIR:-$(dirname "$SCRIPT_DIR")}"
cd "$ROOT_DIR"

# Parse arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  cat << 'EOF'
List YouTube Channel Videos

Usage: vod list-youtube <channel> [options]

Lists all videos from a YouTube channel (excludes shorts and live streams).

Arguments:
  channel         YouTube channel handle (@name), URL, or channel ID

Options:
  --urls-only     Output only URLs (one per line)
  --limit N       Limit to N most recent videos
  --output, -o    Save URLs to file named after channel (e.g., urls-MrBeast)
  --json          Output full JSON metadata
  -h, --help      Show this help message

Examples:
  vod list-youtube @MrBeast                          # List all videos
  vod list-youtube @MrBeast --urls-only              # Just URLs
  vod list-youtube @MrBeast --limit 20               # Last 20 videos
  vod list-youtube @MrBeast --urls-only >> urls-vods # Add to download queue
  vod list-youtube @MrBeast -o                       # Save to urls-MrBeast
  vod list-youtube "https://www.youtube.com/@MrBeast"
EOF
  exit 0
fi

CHANNEL="$1"
shift

# Default options
URLS_ONLY=false
LIMIT=""
JSON_OUTPUT=false
OUTPUT_TO_FILE=false

# Parse remaining arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --urls-only)
      URLS_ONLY=true
      shift
      ;;
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --output|-o)
      OUTPUT_TO_FILE=true
      URLS_ONLY=true  # Implies urls-only
      shift
      ;;
    *)
      echo "Error: Unknown option: $1"
      exit 1
      ;;
  esac
done

# Build the YouTube channel videos URL
# If it's just a handle (starts with @), convert to full URL
if [[ "$CHANNEL" =~ ^@ ]]; then
  YOUTUBE_URL="https://www.youtube.com/${CHANNEL}/videos"
elif [[ "$CHANNEL" =~ ^https?:// ]]; then
  # Already a URL - ensure we're looking at /videos
  YOUTUBE_URL="${CHANNEL%/}"
  # Remove any existing path suffix and add /videos
  YOUTUBE_URL="${YOUTUBE_URL%/videos}"
  YOUTUBE_URL="${YOUTUBE_URL%/streams}"
  YOUTUBE_URL="${YOUTUBE_URL%/shorts}"
  YOUTUBE_URL="${YOUTUBE_URL}/videos"
else
  # Assume it's a channel ID or name
  YOUTUBE_URL="https://www.youtube.com/${CHANNEL}/videos"
fi

# Build yt-dlp command
# --match-filter to exclude shorts (duration > 60s) and live streams
YT_DLP_ARGS=(
  --no-warnings
  --match-filter "duration>60 & !is_live"
)

if [ -n "$LIMIT" ]; then
  YT_DLP_ARGS+=(--playlist-end "$LIMIT")
fi

# Extract channel name for output file (if needed)
if [ "$OUTPUT_TO_FILE" = true ]; then
  # Get channel name from yt-dlp
  channel_name=$(yt-dlp --no-warnings --flat-playlist --playlist-end 1 --print "%(channel)s" "$YOUTUBE_URL" 2>/dev/null | head -1)
  if [ -z "$channel_name" ]; then
    # Fallback: extract from URL or input
    if [[ "$CHANNEL" =~ ^@ ]]; then
      channel_name="${CHANNEL#@}"
    else
      channel_name=$(basename "$YOUTUBE_URL" | sed 's/videos//' | sed 's/^@//')
    fi
  fi
  # Sanitize channel name for filename
  channel_name_clean=$(echo "$channel_name" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
  OUTPUT_FILE="urls-${channel_name_clean}"
  echo "Channel: $channel_name"
  echo "Output file: $OUTPUT_FILE"
fi

if [ "$JSON_OUTPUT" = true ]; then
  # Full JSON output
  yt-dlp "${YT_DLP_ARGS[@]}" --dump-json "$YOUTUBE_URL"
elif [ "$URLS_ONLY" = true ]; then
  if [ "$OUTPUT_TO_FILE" = true ]; then
    # Save to file
    echo "Fetching video URLs..."
    yt-dlp "${YT_DLP_ARGS[@]}" --flat-playlist --print url "$YOUTUBE_URL" > "$OUTPUT_FILE"
    count=$(wc -l < "$OUTPUT_FILE")
    echo "Saved $count URLs to $OUTPUT_FILE"
  else
    # Just URLs to stdout
    yt-dlp "${YT_DLP_ARGS[@]}" --flat-playlist --print url "$YOUTUBE_URL"
  fi
else
  # Human-readable format: date, duration, title, URL
  echo "Fetching videos from: $YOUTUBE_URL"
  echo "Excluding: Shorts (<60s), Live streams"
  echo ""
  yt-dlp "${YT_DLP_ARGS[@]}" --flat-playlist \
    --print "%(upload_date>%Y-%m-%d)s | %(duration_string)s | %(title).60s | %(webpage_url)s" \
    "$YOUTUBE_URL" | column -t -s '|'
fi
