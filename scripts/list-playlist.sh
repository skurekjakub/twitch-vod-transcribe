#!/bin/bash

# List YouTube Playlist Videos
# Lists all videos from a YouTube playlist
#
# Usage: vod list-playlist <playlist_url> [options]
# 
# Examples:
#   vod list-playlist "https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"
#   vod list-playlist PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf --urls-only
#   vod list-playlist PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf -o
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
List YouTube Playlist Videos

Usage: vod list-playlist <playlist> [options]

Lists all videos from a YouTube playlist.

Arguments:
  playlist        YouTube playlist URL or playlist ID (PLxxxxx)

Options:
  --urls-only     Output only URLs (one per line)
  --limit N       Limit to N videos
  --output, -o    Save URLs to file named after playlist
  --json          Output full JSON metadata
  -h, --help      Show this help message

Examples:
  vod list-playlist "https://www.youtube.com/playlist?list=PLxxxxx"
  vod list-playlist PLxxxxx --urls-only              # Just URLs
  vod list-playlist PLxxxxx --limit 20               # First 20 videos
  vod list-playlist PLxxxxx -o                       # Save to urls-{playlist_name}
  vod list-playlist PLxxxxx --urls-only >> urls-vods # Add to download queue
EOF
  exit 0
fi

PLAYLIST="$1"
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

# Build the YouTube playlist URL
# If it's just a playlist ID (starts with PL), convert to full URL
if [[ "$PLAYLIST" =~ ^PL ]]; then
  YOUTUBE_URL="https://www.youtube.com/playlist?list=${PLAYLIST}"
elif [[ "$PLAYLIST" =~ ^https?:// ]]; then
  YOUTUBE_URL="$PLAYLIST"
else
  # Assume it's a playlist ID
  YOUTUBE_URL="https://www.youtube.com/playlist?list=${PLAYLIST}"
fi

# Build yt-dlp command
YT_DLP_ARGS=(
  --no-warnings
)

if [ -n "$LIMIT" ]; then
  YT_DLP_ARGS+=(--playlist-end "$LIMIT")
fi

# Extract playlist name for output file (if needed)
if [ "$OUTPUT_TO_FILE" = true ]; then
  # Get playlist title from yt-dlp
  playlist_name=$(yt-dlp --no-warnings --flat-playlist --playlist-end 1 --print "%(playlist_title)s" "$YOUTUBE_URL" 2>/dev/null | head -1)
  if [ -z "$playlist_name" ] || [ "$playlist_name" = "NA" ]; then
    # Fallback: extract playlist ID from URL
    playlist_name=$(echo "$YOUTUBE_URL" | grep -oP 'list=\K[^&]+' || echo "playlist")
  fi
  # Sanitize playlist name for filename
  playlist_name_clean=$(echo "$playlist_name" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | tr '[:upper:]' '[:lower:]')
  OUTPUT_FILE="urls-${playlist_name_clean}"
  echo "Playlist: $playlist_name"
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
  # Human-readable format: index, duration, title, URL
  echo "Fetching videos from playlist: $YOUTUBE_URL"
  echo ""
  yt-dlp "${YT_DLP_ARGS[@]}" --flat-playlist \
    --print "%(playlist_index)3s | %(duration_string)s | %(title).60s | %(webpage_url)s" \
    "$YOUTUBE_URL" | column -t -s '|'
fi
