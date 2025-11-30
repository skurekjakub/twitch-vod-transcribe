#!/bin/bash
set -e

# YouTube Transcript Fetcher (using yt-dlp)
# Fetches transcript/captions from a YouTube video without API keys
#
# Usage: vod youtube [--download] [--lang LANG] <youtube_url>
# 
# Examples:
#   vod youtube https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   vod youtube --lang en https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   vod youtube --download https://www.youtube.com/watch?v=dQw4w9WgXcQ
#
# Dependencies: yt-dlp (install: pip install yt-dlp), ffmpeg

# Get the root directory (parent of scripts/) - can be overridden for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${VOD_ROOT_DIR:-$(dirname "$SCRIPT_DIR")}"
cd "$ROOT_DIR"

# Lib script paths - can be overridden for testing
TRANSCRIBE_AUDIO_SCRIPT="${TRANSCRIBE_AUDIO_SCRIPT:-./lib/transcribe-audio.sh}"

# Default values
LANG="en"
DOWNLOAD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'EOF'
YouTube Transcript Fetcher (using yt-dlp)

Usage: vod youtube [options] <youtube_url>

Fetches YouTube captions/transcripts. Falls back to Whisper transcription
if no captions are available and --download is specified.

Options:
  --download              Download audio and transcribe with Whisper
  --lang LANG             Preferred caption language (default: en)
  -h, --help              Show this help message

Examples:
  vod youtube https://www.youtube.com/watch?v=dQw4w9WgXcQ
  vod youtube --lang es https://www.youtube.com/watch?v=dQw4w9WgXcQ
  vod youtube --download https://www.youtube.com/watch?v=dQw4w9WgXcQ

Output:
  - Transcript: transcripts/youtube/<channel>-<date>-<title>-<lang>.txt
  - Audio (if --download): vods/youtube/<channel>-<date>-<title>.aac
EOF
      exit 0
      ;;
    --download)
      DOWNLOAD=true
      shift
      ;;
    --lang)
      LANG="$2"
      shift 2
      ;;
    https://www.youtube.com/*|https://youtu.be/*)
      VIDEO_URL="$1"
      shift
      ;;
    *)
      echo "Error: Unknown argument: $1"
      echo "Usage: vod youtube [--download] [--lang LANG] <youtube_url>"
      exit 1
      ;;
  esac
done

# Validate URL
if [[ -z "$VIDEO_URL" ]]; then
  echo "Error: Missing YouTube video URL!"
  echo "Usage: vod youtube [--download] [--lang LANG] <youtube_url>"
  echo "Example: vod youtube https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  exit 1
fi

# Extract video ID from various YouTube URL formats
if [[ "$VIDEO_URL" =~ v=([a-zA-Z0-9_-]{11}) ]]; then
  VIDEO_ID="${BASH_REMATCH[1]}"
elif [[ "$VIDEO_URL" =~ youtu\.be/([a-zA-Z0-9_-]{11}) ]]; then
  VIDEO_ID="${BASH_REMATCH[1]}"
else
  echo "Error: Could not extract video ID from URL: $VIDEO_URL"
  echo "Supported formats:"
  echo "  - https://www.youtube.com/watch?v=VIDEO_ID"
  echo "  - https://youtu.be/VIDEO_ID"
  exit 1
fi

# Check if yt-dlp is installed
if ! command -v yt-dlp &> /dev/null; then
  echo "Error: yt-dlp is not installed"
  echo "Install with: pip install yt-dlp"
  exit 1
fi

# Build cookie arguments for yt-dlp (for YouTube Premium, age-restricted videos, etc.)
# Auto-detect cookies.txt in project root
YTDLP_COOKIE_ARGS=()
if [[ -f "${ROOT_DIR}/cookies.txt" ]]; then
  YTDLP_COOKIE_ARGS=(--cookies "${ROOT_DIR}/cookies.txt")
fi

timestamp=$(date "+%Y.%m.%d-%H:%M:%S")

# Create directory structures
transcript_dir="transcripts/youtube"
vod_dir="vods/youtube"
logs_dir="logs"
mkdir -p "$transcript_dir" "$vod_dir" "$logs_dir"

echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "YouTube Transcript Fetcher (yt-dlp)" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Video ID: $VIDEO_ID" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "URL: $VIDEO_URL" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Preferred Language: $LANG" | tee -a "${logs_dir}/run-${timestamp}.log"
if [ "$DOWNLOAD" = true ]; then
  echo "Download Mode: Enabled (video download + audio extraction + transcription)" | tee -a "${logs_dir}/run-${timestamp}.log"
fi
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"

# Step 1: Get video metadata
echo "$VIDEO_ID - $timestamp - Fetching video metadata" | tee -a "${logs_dir}/run-${timestamp}.log"

# Get video info in JSON format
if ! video_info=$(yt-dlp "${YTDLP_COOKIE_ARGS[@]}" --dump-json --no-warnings "$VIDEO_URL" 2>&1); then
  echo "Error: Failed to fetch video information" | tee -a "${logs_dir}/run-${timestamp}.log"
  echo "$video_info" | tee -a "${logs_dir}/run-${timestamp}.log"
  exit 1
fi

# Extract video details using grep and sed (avoiding jq dependency)
video_title=$(echo "$video_info" | grep -o '"title": *"[^"]*"' | head -n 1 | sed 's/"title": *"\(.*\)"/\1/')
channel_name=$(echo "$video_info" | grep -o '"uploader": *"[^"]*"' | head -n 1 | sed 's/"uploader": *"\(.*\)"/\1/')
upload_date=$(echo "$video_info" | grep -o '"upload_date": *"[^"]*"' | head -n 1 | sed 's/"upload_date": *"\(.*\)"/\1/')

# Format date (YYYYMMDD -> YYYY-MM-DD)
if [[ "$upload_date" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})$ ]]; then
  date_part="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
else
  date_part=$(date "+%Y-%m-%d")
fi

# Clean up channel and title for filenames
channel_clean=$(echo "$channel_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
title_clean=$(echo "$video_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/-/g' | sed 's/ /-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
title_short="${title_clean:0:20}"

base_name="${channel_clean}-${date_part}-${title_short}"

echo "$VIDEO_ID - $timestamp - Video: $video_title" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "$VIDEO_ID - $timestamp - Channel: $channel_name" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "$VIDEO_ID - $timestamp - Published: $date_part" | tee -a "${logs_dir}/run-${timestamp}.log"

# Step 2: List available subtitles
echo "$VIDEO_ID - $timestamp - Checking available subtitles" | tee -a "${logs_dir}/run-${timestamp}.log"

yt-dlp "${YTDLP_COOKIE_ARGS[@]}" --list-subs "$VIDEO_URL" 2>&1 | tee -a "${logs_dir}/run-${timestamp}.log"

# Step 3: Download subtitles
temp_srt_file="${transcript_dir}/${base_name}-${LANG}.srt"
output_file="${transcript_dir}/${base_name}-${LANG}.txt"
transcript_downloaded=false

echo "$VIDEO_ID - $timestamp - Downloading subtitles" | tee -a "${logs_dir}/run-${timestamp}.log"

# Download subtitles in SRT format
# Try manual subtitles first, then auto-generated
yt-dlp \
  "${YTDLP_COOKIE_ARGS[@]}" \
  --write-subs \
  --write-auto-subs \
  --sub-lang "${LANG}" \
  --sub-format "srt" \
  --skip-download \
  --output "${transcript_dir}/${base_name}.%(ext)s" \
  --no-warnings \
  "$VIDEO_URL" 2>&1 | tee -a "${logs_dir}/run-${timestamp}.log"

# Find the downloaded subtitle file
subtitle_file=$(find "${transcript_dir}" -maxdepth 1 -name "${base_name}.*.srt" -type f 2>/dev/null | head -n 1)

if [ -z "$subtitle_file" ]; then
  echo "$VIDEO_ID - $timestamp - Warning: No subtitles found for language: $LANG" | tee -a "${logs_dir}/run-${timestamp}.log"
  
  # If download mode is not enabled, this is an error
  if [ "$DOWNLOAD" = false ]; then
    echo "Error: No subtitles available and --download not specified" | tee -a "${logs_dir}/run-${timestamp}.log"
    echo "Try running with --list-subs to see available languages" | tee -a "${logs_dir}/run-${timestamp}.log"
    exit 1
  else
    echo "$VIDEO_ID - $timestamp - Continuing with download only (no transcript)" | tee -a "${logs_dir}/run-${timestamp}.log"
  fi
else
  # Rename to temporary SRT file
  mv "$subtitle_file" "$temp_srt_file"

  # Step 4: Convert SRT to plain text (remove timestamps and sequence numbers)
  echo "$VIDEO_ID - $timestamp - Converting to plain text format" | tee -a "${logs_dir}/run-${timestamp}.log"

  # Remove timestamps and sequence numbers, keep only text
  # SRT format has: sequence number, timestamp line, text line(s), blank line
  grep -v '^[0-9]*$' "$temp_srt_file" | \
    grep -v '^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]' | \
    grep -v '^$' | \
    sed 's/<[^>]*>//g' > "$output_file"

  # Clean up temporary SRT file
  rm -f "$temp_srt_file"

  echo "$VIDEO_ID - $timestamp - Transcript saved" | tee -a "${logs_dir}/run-${timestamp}.log"
  transcript_downloaded=true
fi

# Step 5: Download video and extract audio (optional)
if [ "$DOWNLOAD" = true ]; then
  echo "$VIDEO_ID - $timestamp - Downloading and extracting audio to AAC" | tee -a "${logs_dir}/run-${timestamp}.log"
  
  audio_file_base="${vod_dir}/${base_name}"
  
  # Download the best audio-only stream and convert it to AAC
  # -x --audio-format aac = "Extract audio and *force convert* to AAC"
  yt-dlp \
    "${YTDLP_COOKIE_ARGS[@]}" \
    -x \
    --audio-format aac \
    --output "${audio_file_base}.%(ext)s" \
    --no-warnings \
    "$VIDEO_URL"
  
  # Find the actual audio file created (could be .aac, .m4a, etc.)
  audio_file=$(find "$(dirname "$audio_file_base")" -maxdepth 1 -name "$(basename "$audio_file_base").*" -type f \( -name "*.aac" -o -name "*.m4a" -o -name "*.opus" -o -name "*.webm" \) 2>/dev/null | head -n 1)
  
  if [ -z "$audio_file" ]; then
    echo "$VIDEO_ID - $timestamp - Error: No audio file found matching ${audio_file_base}.*" | tee -a "${logs_dir}/run-${timestamp}.log"
    exit 1
  fi
  
  echo "$VIDEO_ID - $timestamp - Audio extraction completed: $audio_file" | tee -a "${logs_dir}/run-${timestamp}.log"
  
  # If no transcript was downloaded from YouTube, transcribe the audio
  if [ "$transcript_downloaded" = false ]; then
    echo "$VIDEO_ID - $timestamp - No subtitles available, transcribing audio with Whisper" | tee -a "${logs_dir}/run-${timestamp}.log"
    
    # Check if the audio file was actually created
    if [ ! -f "$audio_file" ]; then
        echo "$VIDEO_ID - $timestamp - Error: Audio file $audio_file was not created." | tee -a "${logs_dir}/run-${timestamp}.log"
        exit 1
    fi

    "$TRANSCRIBE_AUDIO_SCRIPT" "$audio_file" "$output_file"
    
    transcript_downloaded=true
    echo "$VIDEO_ID - $timestamp - Audio transcription completed" | tee -a "${logs_dir}/run-${timestamp}.log"
  fi
fi

# Summary
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Processing completed successfully!" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Output files:" | tee -a "${logs_dir}/run-${timestamp}.log"
if [ "$transcript_downloaded" = true ]; then
  echo "  - Transcript (plain text): $output_file" | tee -a "${logs_dir}/run-${timestamp}.log"
  echo "  - Language: $LANG" | tee -a "${logs_dir}/run-${timestamp}.log"
fi
if [ "$DOWNLOAD" = true ]; then
  echo "  - Audio: $audio_file" | tee -a "${logs_dir}/run-${timestamp}.log"
fi
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
