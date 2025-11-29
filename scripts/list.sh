#!/bin/bash

# List Twitch VODs for a Channel
# Scrapes a Twitch channel and lists all available VODs (past broadcasts)
#
# Usage: vod list <channel_name> [options]
# 
# Examples:
#   vod list forsen                    # List all VODs
#   vod list forsen --urls-only        # Just URLs (for piping to urls-vods)
#   vod list forsen --limit 10         # Last 10 VODs only
#   vod list forsen --chapters         # Include chapter info
#   vod list forsen --urls-only >> urls-vods   # Append to download queue
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
List Twitch VODs for a Channel

Usage: vod list <channel_name> [options]

Scrapes a Twitch channel and lists available VODs (past broadcasts).

Options:
  --urls-only     Output only URLs (one per line)
  --limit N       Limit to N most recent VODs
  --chapters      Show chapters for each VOD (slower)
  --json          Output full JSON metadata
  -h, --help      Show this help message

Examples:
  vod list forsen                          # List all VODs with details
  vod list forsen --urls-only              # Just URLs
  vod list forsen --limit 5 --urls-only    # Last 5 VOD URLs
  vod list forsen --chapters --limit 5     # Last 5 with chapter info
  vod list forsen --urls-only >> urls-vods # Add to download queue
EOF
  exit 0
fi

CHANNEL="$1"
shift

# Default options
URLS_ONLY=false
LIMIT=""
JSON_OUTPUT=false
SHOW_CHAPTERS=false

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
    --chapters)
      SHOW_CHAPTERS=true
      shift
      ;;
    *)
      echo "Error: Unknown option: $1"
      exit 1
      ;;
  esac
done

# Build the Twitch VODs URL
# Format: https://www.twitch.tv/<channel>/videos?filter=archives
# "archives" = Past Broadcasts (VODs), excludes clips and highlights
TWITCH_URL="https://www.twitch.tv/${CHANNEL}/videos?filter=archives"

# Build yt-dlp command
YT_DLP_ARGS=(
  --no-warnings
)

if [ -n "$LIMIT" ]; then
  YT_DLP_ARGS+=(--playlist-end "$LIMIT")
fi

if [ "$JSON_OUTPUT" = true ]; then
  # Full JSON output (not flat, to get chapters)
  yt-dlp "${YT_DLP_ARGS[@]}" --dump-json "$TWITCH_URL"
elif [ "$URLS_ONLY" = true ]; then
  # Just URLs
  yt-dlp "${YT_DLP_ARGS[@]}" --flat-playlist --print url "$TWITCH_URL"
elif [ "$SHOW_CHAPTERS" = true ]; then
  # With chapters - need full metadata extraction (slower)
  echo "Fetching VODs with chapter info (this may take a moment)..."
  echo ""
  
  # Get full JSON and parse it
  yt-dlp "${YT_DLP_ARGS[@]}" --dump-json "$TWITCH_URL" 2>/dev/null | while read -r json; do
    # Extract basic info
    title=$(echo "$json" | grep -o '"title": *"[^"]*"' | head -n1 | sed 's/"title": *"\(.*\)"/\1/')
    url=$(echo "$json" | grep -o '"webpage_url": *"[^"]*"' | head -n1 | sed 's/"webpage_url": *"\(.*\)"/\1/')
    duration=$(echo "$json" | grep -o '"duration_string": *"[^"]*"' | head -n1 | sed 's/"duration_string": *"\(.*\)"/\1/')
    upload_date=$(echo "$json" | grep -o '"upload_date": *"[^"]*"' | head -n1 | sed 's/"upload_date": *"\(.*\)"/\1/')
    
    # Format date
    if [[ "$upload_date" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})$ ]]; then
      date_formatted="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    else
      date_formatted="$upload_date"
    fi
    
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "📺 $title"
    echo "📅 $date_formatted | ⏱️  $duration"
    echo "🔗 $url"
    
    # Extract chapters if present
    if echo "$json" | grep -q '"chapters":'; then
      echo "📑 Chapters:"
      # Parse chapters array - extract title and start_time
      echo "$json" | grep -o '"chapters": *\[[^]]*\]' | \
        grep -o '{"title": *"[^"]*", *"start_time": *[0-9.]*' | \
        while read -r chapter; do
          ch_title=$(echo "$chapter" | grep -o '"title": *"[^"]*"' | sed 's/"title": *"\(.*\)"/\1/')
          ch_start=$(echo "$chapter" | grep -o '"start_time": *[0-9.]*' | sed 's/"start_time": *//')
          # Convert seconds to HH:MM:SS
          ch_start_int=${ch_start%.*}
          hours=$((ch_start_int / 3600))
          minutes=$(( (ch_start_int % 3600) / 60 ))
          seconds=$((ch_start_int % 60))
          printf "   %02d:%02d:%02d - %s\n" "$hours" "$minutes" "$seconds" "$ch_title"
        done
    else
      echo "📑 No chapters found"
    fi
    echo ""
  done
else
  # Human-readable format: date, duration, title, URL (fast, flat playlist)
  yt-dlp "${YT_DLP_ARGS[@]}" --flat-playlist \
    --print "%(upload_date>%Y-%m-%d)s | %(duration_string)s | %(title).60s | %(webpage_url)s" \
    "$TWITCH_URL" | column -t -s '|'
fi
