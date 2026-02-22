#!/bin/bash
set -e

# Video Downloader (using yt-dlp)
# Downloads video at highest available quality from YouTube or other supported sites
#
# Usage: vod download <video_url> [prefix]
# 
# Examples:
#   vod download https://www.youtube.com/watch?v=dQw4w9WgXcQ
#   vod download https://youtu.be/jNQXAC9IVRw
#   vod download https://www.twitch.tv/videos/12345 my-prefix
#
# Dependencies: yt-dlp (install: pip install yt-dlp)

# Get the root directory (parent of scripts/) - can be overridden for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${VOD_ROOT_DIR:-$(dirname "$SCRIPT_DIR")}"
cd "$ROOT_DIR"

# Parse arguments - extract URL, prefix, and any extra args after --
VIDEO_URL=""
URL_PREFIX=""
EXTRA_ARGS=()

# Check for help first
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  cat << 'EOF'
Video Downloader (using yt-dlp)

Usage: vod download <video_url> [prefix] [-- <yt-dlp args>...]

Downloads video at highest available quality.
Saves to $DOWNLOADS_DIR/<channel>/ if set, otherwise videos/<channel>/ under the project root.
If NAS is mounted at /nas, files are also copied to /nas/vods/<channel>/.

Arguments:
  video_url       URL of the video to download
  prefix          Optional filename prefix
  -- <args>       Pass additional arguments directly to yt-dlp

Options:
  -h, --help      Show this help message

Examples:
  vod download https://www.youtube.com/watch?v=dQw4w9WgXcQ
  vod download https://youtu.be/jNQXAC9IVRw my-prefix
  vod download https://www.twitch.tv/videos/12345 my-prefix
  vod download https://example.com/video -- --extractor-args "generic:impersonate"
  vod download https://site.com/video -- --referer "https://site.com" --user-agent "Mozilla/5.0"

Features:
  - Automatic chapter splitting for Twitch videos (disabled for YouTube)
  - Auto-split videos >6 hours into 5-hour chunks
  - Highest resolution available (4K when available)
  - Downloads locally first, then copies to NAS if mounted (safer for network issues)
  - Pass arbitrary yt-dlp options via -- separator
EOF
  exit 0
fi

# Parse positional args and -- separator
while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      EXTRA_ARGS=("$@")
      break
      ;;
    *)
      if [[ -z "$VIDEO_URL" ]]; then
        VIDEO_URL="$1"
      elif [[ -z "$URL_PREFIX" ]]; then
        URL_PREFIX="$1"
      fi
      shift
      ;;
  esac
done

# Detect if this is a YouTube URL
IS_YOUTUBE=false
if [[ "$VIDEO_URL" =~ youtube\.com|youtu\.be ]]; then
  IS_YOUTUBE=true
fi

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

# Build cookie arguments for yt-dlp (for YouTube Premium, age-restricted videos, etc.)
# Auto-detect cookies.txt in project root
YTDLP_COOKIE_ARGS=()
if [[ -f "${ROOT_DIR}/cookies.txt" ]]; then
  YTDLP_COOKIE_ARGS=(--cookies "${ROOT_DIR}/cookies.txt")
fi

timestamp=$(date "+%Y.%m.%d-%H:%M:%S")

# Create directory structures
logs_dir="logs"
mkdir -p "$logs_dir"

echo "========================================" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Video Downloader (yt-dlp)" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "URL: $VIDEO_URL" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Quality: Best available" | tee -a "${logs_dir}/download-${timestamp}.log"
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  echo "Extra args: ${EXTRA_ARGS[*]}" | tee -a "${logs_dir}/download-${timestamp}.log"
fi
echo "========================================" | tee -a "${logs_dir}/download-${timestamp}.log"

# Title output file for batch processing (allows parent scripts to capture the title)
TITLE_OUTPUT_FILE="${TITLE_OUTPUT_FILE:-}"

# Step 1: Get video metadata
echo "Download - $timestamp - Fetching video metadata" | tee -a "${logs_dir}/download-${timestamp}.log"

# Debug: Show exact command being run
echo "Download - $timestamp - Running: yt-dlp ${YTDLP_COOKIE_ARGS[*]} --dump-json --no-warnings ${EXTRA_ARGS[*]} $VIDEO_URL" | tee -a "${logs_dir}/download-${timestamp}.log"

# Get video info in JSON format
if ! video_info=$(yt-dlp "${YTDLP_COOKIE_ARGS[@]}" --dump-json --no-warnings "${EXTRA_ARGS[@]}" "$VIDEO_URL" 2>&1); then
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
# Channel: just sanitize for filesystem (no lowercasing, preserve case)
# Title: Remove Unicode/emoji characters:
# 1. LC_ALL=C strips all non-ASCII bytes (raw emoji)
# 2. Remove escaped \uXXXX sequences
# 3. Remove yt-dlp sanitized surrogate pairs like "ud83d-udd34" (emoji red circle)
channel_clean=$(echo "$channel_name" | \
  sed 's/[^a-zA-Z0-9]/-/g' | \
  sed 's/--*/-/g' | \
  sed 's/^-//' | \
  sed 's/-$//')
title_clean=$(echo "$video_title" | \
  LC_ALL=C sed 's/[\x80-\xFF]//g' | \
  sed 's/\\u[0-9a-fA-F]\{4\}//g' | \
  sed 's/ud83[cd]-ud[a-f0-9]\{3\}//gi' | \
  tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9 ]/-/g' | \
  sed 's/ /-/g' | \
  sed 's/--*/-/g' | \
  sed 's/^-//' | \
  sed 's/-$//')

# Always download locally first, then copy to NAS if mounted
_downloads_base="${DOWNLOADS_DIR:-${ROOT_DIR}/videos}"
video_dir="${_downloads_base}/${channel_clean}"
nas_mounted=false
nas_dir=""
if grep -qs " /nas " /proc/mounts; then
  nas_mounted=true
  nas_dir="/nas/vods/${channel_clean}"
  echo "Download - $timestamp - NAS detected. Will download locally first, then copy to: $nas_dir" | tee -a "${logs_dir}/download-${timestamp}.log"
else
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

# Write title to output file if specified (for batch processing)
if [ -n "$TITLE_OUTPUT_FILE" ]; then
  echo "$video_title" > "$TITLE_OUTPUT_FILE"
fi

# Check if video has chapters (only for non-YouTube videos)
# YouTube chapter splitting is disabled to get single file downloads
# Look for "chapters" array with actual chapter entries (has "start_time" keys)
# Use grep -o to find all occurrences (not just lines), then count with wc -l
has_chapters=0
if [ "$IS_YOUTUBE" = false ]; then
  has_chapters=$(echo "$video_info" | grep -o '"start_time"' 2>/dev/null | wc -l || echo "0")
  has_chapters="${has_chapters//[^0-9]/}"  # Strip any non-numeric characters
  [ -z "$has_chapters" ] && has_chapters=0
fi

if [ "$has_chapters" -gt 1 ]; then
  echo "Download - $timestamp - Video has $has_chapters chapters, will split" | tee -a "${logs_dir}/download-${timestamp}.log"
else
  if [ "$IS_YOUTUBE" = true ]; then
    echo "Download - $timestamp - YouTube video, downloading as single file (chapter splitting disabled)" | tee -a "${logs_dir}/download-${timestamp}.log"
  else
    echo "Download - $timestamp - No chapters found, downloading as single file" | tee -a "${logs_dir}/download-${timestamp}.log"
  fi
fi

# Step 2: Download video at highest quality
echo "Download - $timestamp - Downloading video at highest quality" | tee -a "${logs_dir}/download-${timestamp}.log"

video_file_base="${video_dir}/${base_name}"

# Download best quality video+audio (merged) with compatible codecs
# -S "res,acodec:m4a" = Prioritize highest resolution, then prefer AAC audio
# Sorts by: resolution first (allows 4K/VP9/AV1), then AAC audio preference
# --concurrent-fragments = Download fragments in parallel for faster speeds
# Track if yt-dlp succeeds (we check file existence later as primary validation)
ytdlp_exit_code=0

if [ "$has_chapters" -gt 1 ]; then
  # With chapters: use --split-chapters to create separate files per chapter
  # Chapter output: date-title-##-chaptername.mp4 (## = zero-padded chapter index)
  # %(section_title)#S = sanitize with restricted characters (replaces spaces and special chars)
  # Format priority: h264+m4a (preferred) -> any 720p60 -> any 720p -> best available (unrestricted)
  yt-dlp \
    -v \
    "${YTDLP_COOKIE_ARGS[@]}" \
    --color always \
    -f "bestvideo[height<=720][fps<=60][vcodec*=avc1]+bestaudio[acodec*=mp4a]/bestvideo[height<=720][fps<=60]+bestaudio/best[height<=720][fps<=60]/best[height<=720]/best" \
    --concurrent-fragments 6 \
    --split-chapters \
    --output "${video_file_base}.%(ext)s" \
    --output "chapter:${video_file_base}-%(section_number)02d-%(section_title)#S.%(ext)s" \
    "${EXTRA_ARGS[@]}" \
    "$VIDEO_URL" || ytdlp_exit_code=$?
  
  # Only remove the full video file if chapter files actually exist
  # (yt-dlp may fail to split chapters even if metadata says they exist)
  chapter_count=$(find "$(dirname "$video_file_base")" -maxdepth 1 -type f -name "$(basename "$video_file_base")-[0-9][0-9]-*.mp4" -print 2>/dev/null | wc -l | tr -d '[:space:]')
  if [ "$chapter_count" -gt 0 ]; then
    echo "Download - $timestamp - Found $chapter_count chapter files, removing full video" | tee -a "${logs_dir}/download-${timestamp}.log"
    rm -f "${video_file_base}.mp4"
  else
    echo "Download - $timestamp - Warning: No chapter files created despite metadata indicating chapters exist" | tee -a "${logs_dir}/download-${timestamp}.log"
  fi
else
  # No chapters: download as single file
  # Format priority: h264+m4a (preferred) -> any 720p60 -> any 720p -> best available (unrestricted)
  yt-dlp \
    -v \
    "${YTDLP_COOKIE_ARGS[@]}" \
    --color always \
    -f "bestvideo[height<=720][fps<=60][vcodec*=avc1]+bestaudio[acodec*=mp4a]/bestvideo[height<=720][fps<=60]+bestaudio/best[height<=720][fps<=60]/best[height<=720]/best" \
    --concurrent-fragments 4 \
    --output "${video_file_base}.%(ext)s" \
    "${EXTRA_ARGS[@]}" \
    "$VIDEO_URL" || ytdlp_exit_code=$?
fi

echo "Download - $timestamp - yt-dlp finished" | tee -a "${logs_dir}/download-${timestamp}.log"

# Check if yt-dlp reported an error
if [ "$ytdlp_exit_code" -ne 0 ]; then
  echo "Download - $timestamp - ERROR: yt-dlp exited with code $ytdlp_exit_code" | tee -a "${logs_dir}/download-${timestamp}.log"
  exit 1
fi

# Split any video files longer than 6 hours into 5-hour chunks
MIN_DURATION_TO_SPLIT=21600  # 6 hours in seconds - only split if video is at least this long
echo "Download - $timestamp - Checking for files longer than 6 hours..." | tee -a "${logs_dir}/download-${timestamp}.log"

# Build list of video files to check (both chapter files and single file)
# Check for multiple video extensions (mp4, mkv, webm)
for video_file in "${video_file_base}"*.{mp4,mkv,webm}; do
  [ -f "$video_file" ] || continue
  
  # Get duration in seconds using ffprobe
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | cut -d. -f1)
  
  if [ -n "$duration" ] && [ "$duration" -gt "$MIN_DURATION_TO_SPLIT" ]; then
    echo "Download - $timestamp - Splitting $video_file (${duration}s) into 5-hour chunks" | tee -a "${logs_dir}/download-${timestamp}.log"
    
    # Use the split script (default 5 hours)
    if "${SCRIPT_DIR}/split.sh" "$video_file" 5; then
      # Remove original file after successful split
      rm -f "$video_file"
      echo "Download - $timestamp - Split complete, removed original" | tee -a "${logs_dir}/download-${timestamp}.log"
    else
      echo "Download - $timestamp - Warning: Failed to split $video_file" | tee -a "${logs_dir}/download-${timestamp}.log"
    fi
  fi
done

# Find all downloaded video files (chapters + split parts)
video_files=$(ls "${video_file_base}"*.{mp4,mkv,webm} 2>/dev/null || true)

# Check for partial/incomplete downloads (.part files) BEFORE checking for video files
# This handles interrupted downloads where .part files exist but no complete video
part_files=$(ls "${video_file_base}"*.part 2>/dev/null || true)
if [ -n "$part_files" ]; then
  echo "Download - $timestamp - Error: Found incomplete .part files - download was interrupted" | tee -a "${logs_dir}/download-${timestamp}.log"
  echo "Download - $timestamp - Partial files: $part_files" | tee -a "${logs_dir}/download-${timestamp}.log"
  exit 1
fi
if [ -z "$video_files" ]; then
  echo "Download - $timestamp - Error: No video files found matching ${video_file_base}*" | tee -a "${logs_dir}/download-${timestamp}.log"
  if [ "$ytdlp_exit_code" -ne 0 ]; then
    echo "Download - $timestamp - yt-dlp exited with code $ytdlp_exit_code" | tee -a "${logs_dir}/download-${timestamp}.log"
  fi
  exit 1
fi

file_count=$(echo "$video_files" | wc -l)
echo "Download - $timestamp - Download completed: $file_count file(s)" | tee -a "${logs_dir}/download-${timestamp}.log"

# Get total size
total_size=$(du -ch "$video_files" 2>/dev/null | tail -n 1 | cut -f1)

# Copy to NAS if mounted
final_output_dir="$video_dir"
if [ "$nas_mounted" = true ]; then
  echo "Download - $timestamp - Copying files to NAS: $nas_dir" | tee -a "${logs_dir}/download-${timestamp}.log"
  mkdir -p "$nas_dir"
  
  copy_failed=false
  for video_file in $video_files; do
    filename=$(basename "$video_file")
    echo "Download - $timestamp - Copying: $filename" | tee -a "${logs_dir}/download-${timestamp}.log"
    if cp "$video_file" "$nas_dir/"; then
      echo "Download - $timestamp - Copied: $filename" | tee -a "${logs_dir}/download-${timestamp}.log"
    else
      echo "Download - $timestamp - ERROR: Failed to copy $filename to NAS" | tee -a "${logs_dir}/download-${timestamp}.log"
      copy_failed=true
    fi
  done
  
  if [ "$copy_failed" = true ]; then
    echo "Download - $timestamp - WARNING: Some files failed to copy to NAS. Local files preserved in: $video_dir" | tee -a "${logs_dir}/download-${timestamp}.log"
  else
    # All files copied successfully, remove local copies
    echo "Download - $timestamp - All files copied to NAS successfully, removing local copies" | tee -a "${logs_dir}/download-${timestamp}.log"
    for video_file in $video_files; do
      rm -f "$video_file"
    done
    # Remove local channel directory if empty
    rmdir "$video_dir" 2>/dev/null || true
    final_output_dir="$nas_dir"
    # Update video_files to reflect NAS paths for summary
    video_files=$(ls "${nas_dir}/${base_name}"*.{mp4,mkv,webm} 2>/dev/null || true)
  fi
fi

# Summary
echo "========================================" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Download completed successfully!" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Output files ($file_count):" | tee -a "${logs_dir}/download-${timestamp}.log"
echo "$video_files" | sed 's/^/  - /' | tee -a "${logs_dir}/download-${timestamp}.log"
echo "Total size: $total_size" | tee -a "${logs_dir}/download-${timestamp}.log"
if [ "$nas_mounted" = true ] && [ "$copy_failed" != true ]; then
  echo "Files stored on NAS: $final_output_dir" | tee -a "${logs_dir}/download-${timestamp}.log"
fi
echo "========================================" | tee -a "${logs_dir}/download-${timestamp}.log"

exit 0
