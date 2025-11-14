#!/bin/bash
set -e

# Batch VOD Transcriber
# Processes multiple Twitch/YouTube URLs from a file
#
# Usage: ./batch-transcribe.sh [OPTIONS] [url_file]
# 
# Examples:
#   ./batch-transcribe.sh urls.txt
#   ./batch-transcribe.sh --download-youtube urls.txt
#   ./batch-transcribe.sh --quality 720p --download-youtube urls.txt
#
# URL file format (one URL per line):
#   https://www.twitch.tv/videos/2588036186
#   https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   https://youtu.be/dQw4w9WgXcQ
#
# Blank lines and lines starting with # are ignored
#
# Options:
#   --quality QUALITY       Video quality for Twitch downloads (default: 480p)
#   --download-youtube      Download and transcribe YouTube videos (default: fetch captions only)
#   --download-video-youtube Download video and transcribe YouTube (vs audio-only)
#   --youtube-lang LANG     YouTube caption language (default: en)
#   --continue-on-error     Continue processing remaining URLs if one fails
#
# Dependencies: twitch-dl, yt-dlp, ffmpeg, faster-whisper

cd "$(dirname "$0")"

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
  echo "Default file: urls.txt"
  echo "Example: $0 urls.txt"
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
  
  # Detect URL type
  url_type=$(detect_url_type "$url")
  
  case "$url_type" in
    twitch)
      log "Detected Twitch VOD"
      if [ "$CONTINUE_ON_ERROR" = true ]; then
        if ./vod-transcribe.sh --quality "$QUALITY" "$url"; then
          successful=$((successful + 1))
          log "✓ Successfully processed Twitch VOD"
        else
          failed=$((failed + 1))
          log "✗ Failed to process Twitch VOD (continuing)"
        fi
      else
        ./vod-transcribe.sh --quality "$QUALITY" "$url"
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
        if ./youtube-transcript-ytdlp.sh "${youtube_args[@]}"; then
          successful=$((successful + 1))
          log "✓ Successfully processed YouTube video"
        else
          # If caption fetch failed and download wasn't already enabled, try with --download
          if [ "$DOWNLOAD_YOUTUBE" = false ] && [ "$DOWNLOAD_VIDEO_YOUTUBE" = false ]; then
            log "⚠ Caption fetch failed, retrying with --download (audio transcription)"
            if ./youtube-transcript-ytdlp.sh --download --lang "$YOUTUBE_LANG" "$url"; then
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
        if ./youtube-transcript-ytdlp.sh "${youtube_args[@]}"; then
          successful=$((successful + 1))
          log "✓ Successfully processed YouTube video"
        else
          # If caption fetch failed and download wasn't already enabled, try with --download
          if [ "$DOWNLOAD_YOUTUBE" = false ] && [ "$DOWNLOAD_VIDEO_YOUTUBE" = false ]; then
            log "⚠ Caption fetch failed, retrying with --download (audio transcription)"
            ./youtube-transcript-ytdlp.sh --download --lang "$YOUTUBE_LANG" "$url"
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
