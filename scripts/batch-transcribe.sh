#!/bin/bash
set -e

# Batch VOD Transcriber
# Processes multiple Twitch/YouTube URLs from a file
#
# Usage: vod batch transcribe [OPTIONS] [url_file]
# 
# Examples:
#   vod batch transcribe urls.txt
#   vod batch transcribe --download-youtube urls.txt
#   vod batch transcribe --quality 720p --download-youtube urls.txt
#
# URL file format (one URL per line):
#   https://www.twitch.tv/videos/2588036186
#   https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   https://youtu.be/dQw4w9WgXcQ
#
# Blank lines and lines starting with # are ignored
#
# Dependencies: twitch-dl, yt-dlp, ffmpeg, faster-whisper

# Get the root directory (parent of scripts/) - can be overridden for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${VOD_ROOT_DIR:-$(dirname "$SCRIPT_DIR")}"
cd "$ROOT_DIR"

# Allow overriding scripts (for testing)
TRANSCRIBE_SCRIPT="${TRANSCRIBE_SCRIPT:-${SCRIPT_DIR}/transcribe.sh}"
YOUTUBE_SCRIPT="${YOUTUBE_SCRIPT:-${SCRIPT_DIR}/youtube.sh}"

# Default values
URL_FILE="urls.txt"
QUALITY="480p"
DOWNLOAD_YOUTUBE=false
DOWNLOAD_VIDEO_YOUTUBE=false
YOUTUBE_LANG="en"
CONTINUE_ON_ERROR=false

# Parse arguments
positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'EOF'
Batch VOD Transcriber

Usage: vod batch transcribe [OPTIONS] [url_file]

Processes multiple Twitch/YouTube URLs from a file, downloading and
transcribing each video.

Options:
  --quality QUALITY           Twitch video quality (default: 480p)
  --download-youtube          Download and transcribe YouTube (default: captions only)
  --download-video-youtube    Download video + audio for YouTube
  --youtube-lang LANG         YouTube caption language (default: en)
  --continue-on-error         Continue processing if one URL fails
  -h, --help                  Show this help message

Arguments:
  url_file                    File containing URLs (default: urls.txt)

URL file format:
  https://www.twitch.tv/videos/2588036186
  https://www.youtube.com/watch?v=dQw4w9WgXcQ
  # Comments start with #

Examples:
  vod batch transcribe                              # Process urls.txt
  vod batch transcribe my-urls.txt                  # Custom file
  vod batch transcribe --quality 720p               # Higher quality Twitch
  vod batch transcribe --download-youtube           # Force YouTube transcription
  vod batch transcribe --continue-on-error          # Don't stop on failure
EOF
      exit 0
      ;;
    --quality)
      QUALITY="$2"
      shift 2
      ;;
    --download-youtube)
      DOWNLOAD_YOUTUBE=true
      shift
      ;;
    --download-video-youtube)
      DOWNLOAD_VIDEO_YOUTUBE=true
      DOWNLOAD_YOUTUBE=true
      shift
      ;;
    --youtube-lang)
      YOUTUBE_LANG="$2"
      shift 2
      ;;
    --continue-on-error)
      CONTINUE_ON_ERROR=true
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1"
      echo "Usage: vod batch transcribe [OPTIONS] [url_file]"
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
  echo "Usage: vod batch transcribe [OPTIONS] [url_file]"
  echo "Default file: urls.txt"
  exit 1
fi

# Create directories
mkdir -p logs

# Generate log file
timestamp=$(date +%Y.%m.%d-%H:%M:%S)
log_file="logs/batch-${timestamp}.log"
ID="BATCH"

# Function to log messages
log() {
  echo "$ID - $(date +%Y.%m.%d-%H:%M:%S) - $1" | tee -a "$log_file"
}

# Function to detect URL type
detect_url_type() {
  local url="$1"
  if [[ "$url" =~ ^https://www\.twitch\.tv/videos/[0-9]+$ ]]; then
    echo "twitch"
  elif [[ "$url" =~ ^https://(www\.)?youtube\.com/watch\?v= ]] || [[ "$url" =~ ^https://youtu\.be/ ]]; then
    echo "youtube"
  else
    echo "unknown"
  fi
}

# Start processing
log "Starting batch transcription from: $URL_FILE"
log "Options: Twitch quality=$QUALITY, YouTube download=$DOWNLOAD_YOUTUBE, YouTube lang=$YOUTUBE_LANG"

# Count total URLs (excluding blank lines and comments)
total_urls=$(grep -cvE '^[[:space:]]*$|^[[:space:]]*#' "$URL_FILE" || echo 0)
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
  
  # Detect URL type
  url_type=$(detect_url_type "$url")
  
  case "$url_type" in
    twitch)
      log "Detected Twitch VOD"
      if [ "$CONTINUE_ON_ERROR" = true ]; then
        if "$TRANSCRIBE_SCRIPT" --quality "$QUALITY" "$url"; then
          successful=$((successful + 1))
          log "✓ Successfully processed Twitch VOD"
        else
          failed=$((failed + 1))
          log "✗ Failed to process Twitch VOD (continuing)"
        fi
      else
        "$TRANSCRIBE_SCRIPT" --quality "$QUALITY" "$url"
        successful=$((successful + 1))
        log "✓ Successfully processed Twitch VOD"
      fi
      ;;
      
    youtube)
      log "Detected YouTube video"
      
      # Build YouTube script arguments as an array to handle special characters in URLs
      youtube_args=()
      
      if [ "$DOWNLOAD_VIDEO_YOUTUBE" = true ]; then
        youtube_args+=("--download-video")
      elif [ "$DOWNLOAD_YOUTUBE" = true ]; then
        youtube_args+=("--download")
      fi
      
      youtube_args+=("--lang" "$YOUTUBE_LANG" "$url")
      
      if [ "$CONTINUE_ON_ERROR" = true ]; then
        if "$YOUTUBE_SCRIPT" "${youtube_args[@]}"; then
          successful=$((successful + 1))
          log "✓ Successfully processed YouTube video"
        else
          # If caption fetch failed and download wasn't already enabled, try with --download
          if [ "$DOWNLOAD_YOUTUBE" = false ] && [ "$DOWNLOAD_VIDEO_YOUTUBE" = false ]; then
            log "⚠ Caption fetch failed, retrying with --download (audio transcription)"
            if "$YOUTUBE_SCRIPT" --download --lang "$YOUTUBE_LANG" "$url"; then
              successful=$((successful + 1))
              log "✓ Successfully processed YouTube video with audio transcription"
            else
              failed=$((failed + 1))
              log "✗ Failed to process YouTube video (continuing)"
            fi
          else
            failed=$((failed + 1))
            log "✗ Failed to process YouTube video (continuing)"
          fi
        fi
      else
        if "$YOUTUBE_SCRIPT" "${youtube_args[@]}"; then
          successful=$((successful + 1))
          log "✓ Successfully processed YouTube video"
        else
          # If caption fetch failed and download wasn't already enabled, try with --download
          if [ "$DOWNLOAD_YOUTUBE" = false ] && [ "$DOWNLOAD_VIDEO_YOUTUBE" = false ]; then
            log "⚠ Caption fetch failed, retrying with --download (audio transcription)"
            "$YOUTUBE_SCRIPT" --download --lang "$YOUTUBE_LANG" "$url"
            successful=$((successful + 1))
            log "✓ Successfully processed YouTube video with audio transcription"
          else
            # Re-throw error if download was already enabled
            exit 1
          fi
        fi
      fi
      ;;
      
    unknown)
      log "⚠ Unknown URL format, skipping: $url"
      skipped=$((skipped + 1))
      ;;
  esac
  
done < "$URL_FILE"

# Summary
log ""
log "========================================"
log "Batch processing complete!"
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
