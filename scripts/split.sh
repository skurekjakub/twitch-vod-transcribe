#!/bin/bash
set -e

# Video Splitter
# Splits video files into time-based chunks
#
# Usage: vod split <video_file> [max_hours]
# 
# Examples:
#   vod split video.mp4              # Split into 5-hour chunks (default)
#   vod split video.mp4 3            # Split into 3-hour chunks
#   vod split /path/to/video.mp4     # Absolute path
#
# Dependencies: ffmpeg, ffprobe

# Get the root directory (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Parse arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  cat << 'EOF'
Video Splitter

Usage: vod split <video_file> [max_hours]

Splits video files into time-based chunks using ffmpeg segment.

Arguments:
  video_file      Path to the video file to split
  max_hours       Maximum duration per chunk in hours (default: 5)

Options:
  -h, --help      Show this help message

Examples:
  vod split video.mp4              # Split into 5-hour chunks
  vod split video.mp4 3            # Split into 3-hour chunks
  vod split /path/to/video.mp4 2   # 2-hour chunks with absolute path

Output:
  Creates files named <original>-part00.mp4, <original>-part01.mp4, etc.
  Original file is preserved.
EOF
  exit 0
fi

VIDEO_FILE="$1"
MAX_HOURS="${2:-5}"  # Default to 5 hours

# Validate file exists
if [[ ! -f "$VIDEO_FILE" ]]; then
  echo "Error: File not found: $VIDEO_FILE"
  exit 1
fi

# Check dependencies
if ! command -v ffprobe &> /dev/null; then
  echo "Error: ffprobe is not installed (part of ffmpeg)"
  exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg is not installed"
  exit 1
fi

# Calculate max duration in seconds
MAX_DURATION=$((MAX_HOURS * 3600))

echo "========================================"
echo "Video Splitter"
echo "File: $VIDEO_FILE"
echo "Max chunk duration: ${MAX_HOURS} hours (${MAX_DURATION}s)"
echo "========================================"

# Get video duration in seconds
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE" 2>/dev/null | cut -d. -f1)

if [[ -z "$duration" ]]; then
  echo "Error: Could not determine video duration"
  exit 1
fi

# Convert to human readable
hours=$((duration / 3600))
minutes=$(((duration % 3600) / 60))
seconds=$((duration % 60))
echo "Video duration: ${hours}h ${minutes}m ${seconds}s (${duration}s)"

# Check if split is needed
if [[ "$duration" -le "$MAX_DURATION" ]]; then
  echo "Video is shorter than ${MAX_HOURS} hours. No split needed."
  exit 0
fi

# Calculate number of parts
num_parts=$(( (duration + MAX_DURATION - 1) / MAX_DURATION ))
echo "Will split into $num_parts parts"

# Get file info
video_dir=$(dirname "$VIDEO_FILE")
video_basename=$(basename "$VIDEO_FILE")
video_name="${video_basename%.*}"
video_ext="${video_basename##*.}"

# Output pattern
output_pattern="${video_dir}/${video_name}-part%02d.${video_ext}"

echo "Output pattern: $output_pattern"
echo "Splitting..."

# Split using ffmpeg segment
ffmpeg -i "$VIDEO_FILE" \
  -c copy \
  -map 0 \
  -segment_time "$MAX_DURATION" \
  -f segment \
  -reset_timestamps 1 \
  "$output_pattern"

if [[ $? -eq 0 ]]; then
  echo "========================================"
  echo "Split completed successfully!"
  echo "Output files:"
  ls -lh "${video_dir}/${video_name}-part"*.${video_ext} 2>/dev/null | awk '{print "  - " $NF " (" $5 ")"}'
  echo ""
  echo "Original file preserved: $VIDEO_FILE"
  echo "To remove original: rm \"$VIDEO_FILE\""
  echo "========================================"
else
  echo "Error: Split failed"
  exit 1
fi
