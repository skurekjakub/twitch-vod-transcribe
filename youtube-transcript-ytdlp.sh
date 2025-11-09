#!/bin/bash
set -e

# YouTube Transcript Fetcher (using yt-dlp)
# Fetches transcript/captions from a YouTube video without API keys
#
# Usage: ./youtube-transcript-ytdlp.sh [--lang LANG] <youtube_url>
# 
# Examples:
#   ./youtube-transcript-ytdlp.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   ./youtube-transcript-ytdlp.sh --lang en https://www.youtube.com/watch?v=dQw4w9WgXcQ
#
# Options:
#   --lang LANG    Preferred caption language (default: en)
#                  Examples: en, es, fr, de, ja, etc.
#
# Dependencies: yt-dlp (install: pip install yt-dlp)

cd "$(dirname "$0")"

# Default values
LANG="en"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
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
      echo "Usage: $0 [--lang LANG] <youtube_url>"
      echo "Example: $0 --lang en https://www.youtube.com/watch?v=dQw4w9WgXcQ"
      exit 1
      ;;
  esac
done

# Validate URL
if [[ -z "$VIDEO_URL" ]]; then
  echo "Error: Missing YouTube video URL!"
  echo "Usage: $0 [--lang LANG] <youtube_url>"
  echo "Example: $0 https://www.youtube.com/watch?v=dQw4w9WgXcQ"
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

timestamp=$(date "+%Y.%m.%d-%H:%M:%S")

# Create directory structures
transcript_dir="transcripts/youtube"
logs_dir="logs"
mkdir -p "$transcript_dir" "$logs_dir"

echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "YouTube Transcript Fetcher (yt-dlp)" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Video ID: $VIDEO_ID" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "URL: $VIDEO_URL" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Preferred Language: $LANG" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"

# Step 1: Get video metadata
echo "$VIDEO_ID - $timestamp - Fetching video metadata" | tee -a "${logs_dir}/run-${timestamp}.log"

# Get video info in JSON format
video_info=$(yt-dlp --dump-json --no-warnings "$VIDEO_URL" 2>&1)

if [ $? -ne 0 ]; then
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

yt-dlp --list-subs "$VIDEO_URL" 2>&1 | tee -a "${logs_dir}/run-${timestamp}.log"

# Step 3: Download subtitles
temp_srt_file="${transcript_dir}/${base_name}-${LANG}.srt"
output_file="${transcript_dir}/${base_name}-${LANG}.txt"

echo "$VIDEO_ID - $timestamp - Downloading subtitles" | tee -a "${logs_dir}/run-${timestamp}.log"

# Download subtitles in SRT format
# Try manual subtitles first, then auto-generated
yt-dlp \
  --write-subs \
  --write-auto-subs \
  --sub-lang "${LANG}" \
  --sub-format "srt" \
  --skip-download \
  --output "${transcript_dir}/${base_name}.%(ext)s" \
  --no-warnings \
  "$VIDEO_URL" 2>&1 | tee -a "${logs_dir}/run-${timestamp}.log"

# Find the downloaded subtitle file
subtitle_file=$(ls "${transcript_dir}/${base_name}."*".srt" 2>/dev/null | head -n 1)

if [ -z "$subtitle_file" ]; then
  echo "Error: No subtitles found for language: $LANG" | tee -a "${logs_dir}/run-${timestamp}.log"
  echo "Try running with --list-subs to see available languages" | tee -a "${logs_dir}/run-${timestamp}.log"
  exit 1
fi

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

# Summary
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Processing completed successfully!" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Output file:" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "  - Transcript (plain text): $output_file" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "  - Language: $LANG" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
