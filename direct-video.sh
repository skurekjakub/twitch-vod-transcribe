#!/bin/bash
set -e

# Video Downloader (using yt-dlp)
# Downloads video at highest available quality from YouTube or other supported sites
#
# Usage: ./download-video.sh <video_url>
# 
# Examples:
#   ./download-video.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   ./download-video.sh https://youtu.be/jNQXAC9IVRw
#
# Dependencies: yt-dlp (install: pip install yt-dlp)

cd "$(dirname "$0")"

# Parse arguments
if [[ $# -eq 0 ]]; then
  echo "Error: Missing video URL!"
  echo "Usage: $0 <video_url> [prefix]"
  echo "Example: $0 https://www.youtube.com/watch?v=dQw4w9WgXcQ my-prefix"
  exit 1
fi

VIDEO_URL="$1"
URL_PREFIX="$2"

# Validate URL (basic check)
if [[ ! "$VIDEO_URL" =~ ^https?:// ]]; then
  echo "Error: Invalid URL format: $VIDEO_URL"
  echo "URL must start with http:// or https://"
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
logs_dir="logs"
mkdir -p "$logs_dir"

echo "========================================" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Video Downloader (yt-dlp)" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "URL: $VIDEO_URL" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Quality: Best available" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/download-${timestamp}.log"

# Step 1: Get video metadata
echo "Download - $timestamp - Fetching video metadata" | tee -a "${logs_dir}/download-${timestamp}.log"

# Get video info in JSON format
video_info=$(yt-dlp --dump-json --no-warnings "$VIDEO_URL" 2>&1)

if [ $? -ne 0 ]; then
  echo "Error: Failed to fetch video information" | tee -a "${logs_dir}/download-${timestamp}.log"
  echo "$video_info" | tee -a "${logs_dir}/download-${timestamp}.log"
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
channel_clean=$(echo "$channel_name" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
title_clean=$(echo "$video_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/-/g' | sed 's/ /-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Determine output directory based on NAS availability
if grep -qs " /nas " /proc/mounts; then
  video_dir="/nas/vods/${channel_clean}"
  echo "Download - $timestamp - NAS detected. Output directory: $video_dir" | tee -a "${logs_dir}/download-${timestamp}.log"
else
  video_dir="videos"
  echo "Download - $timestamp - NAS not detected. Output directory: $video_dir" | tee -a "${logs_dir}/download-${timestamp}.log"
fi
mkdir -p "$video_dir"

base_name="${date_part}-${title_clean}"

if [ -n "$URL_PREFIX" ]; then
  # Sanitize prefix
  prefix_clean=$(echo "$URL_PREFIX" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
  base_name="${prefix_clean}-${base_name}"
fi

echo "Download - $timestamp - Video: $video_title" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Download - $timestamp - Channel: $channel_name" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Download - $timestamp - Published: $date_part" | tee -a "${logs_dir}/download-${timestamp}.log"

# Step 2: Download video at highest quality
echo "Download - $timestamp - Downloading video at highest quality" | tee -a "${logs_dir}/download-${timestamp}.log"

video_file_base="${video_dir}/${base_name}"

# Download best quality video+audio (merged) with compatible codecs
# -S "vcodec:h264,res,acodec:m4a" = "Force H.264 video and AAC audio for TV compatibility"
# Sorts by: H.264 codec preference, then resolution, then AAC audio
# --split-chapters = Split video into separate files per chapter
# Chapter output: date-title-##-chaptername.mp4 (## = zero-padded chapter index)
# %(section_title)#S = sanitize with restricted characters (replaces spaces and special chars)
# Note: No output redirection here to avoid "I/O operation on closed file" error
yt-dlp \
  -S "vcodec:h264,res,acodec:m4a" \
  --split-chapters \
  --output "${video_file_base}.%(ext)s" \
  --output "chapter:${video_file_base}-%(section_number)02d-%(section_title)#S.%(ext)s" \
  "$VIDEO_URL"

rm -f "${video_file_base}.mp4"

echo "Download - $timestamp - yt-dlp finished" | tee -a "${logs_dir}/download-${timestamp}.log"

# Split any chapter files longer than 5 hours into 5-hour chunks (only if at least 6 hours)
MAX_DURATION=18000  # 5 hours in seconds
MIN_DURATION_TO_SPLIT=21600  # 6 hours in seconds - only split if video is at least this long
echo "Download - $timestamp - Checking for files longer than 6 hours..." | tee -a "${logs_dir}/download-${timestamp}.log"

for video_file in "${video_file_base}"-*.mp4; do
  [ -f "$video_file" ] || continue
  
  # Get duration in seconds using ffprobe
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | cut -d. -f1)
  
  if [ -n "$duration" ] && [ "$duration" -gt "$MIN_DURATION_TO_SPLIT" ]; then
    echo "Download - $timestamp - Splitting $video_file (${duration}s) into 5-hour chunks" | tee -a "${logs_dir}/download-${timestamp}.log"
    
    # Get base name without extension
    file_base="${video_file%.mp4}"
    
    # Split using ffmpeg segment
    ffmpeg -i "$video_file" -c copy -map 0 -segment_time $MAX_DURATION -f segment -reset_timestamps 1 "${file_base}-part%02d.mp4" 2>/dev/null
    
    if [ $? -eq 0 ]; then
      # Remove original file after successful split
      rm -f "$video_file"
      echo "Download - $timestamp - Split complete, removed original" | tee -a "${logs_dir}/download-${timestamp}.log"
    else
      echo "Download - $timestamp - Warning: Failed to split $video_file" | tee -a "${logs_dir}/download-${timestamp}.log"
    fi
  fi
done

# Find all downloaded video files (chapters + split parts)
video_files=$(ls "${video_file_base}"*.mp4 2>/dev/null)

if [ -z "$video_files" ]; then
  echo "Download - $timestamp - Error: No video files found matching ${video_file_base}*.mp4" | tee -a "${logs_dir}/download-${timestamp}.log"
  exit 1
fi

file_count=$(echo "$video_files" | wc -l)
echo "Download - $timestamp - Download completed: $file_count file(s)" | tee -a "${logs_dir}/download-${timestamp}.log"

# Get total size
total_size=$(du -ch $video_files 2>/dev/null | tail -n 1 | cut -f1)

# Summary
echo "========================================" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Download completed successfully!" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Output files ($file_count):" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "$video_files" | sed 's/^/  - /' | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Total size: $total_size" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/download-${timestamp}.log"

exit 0
