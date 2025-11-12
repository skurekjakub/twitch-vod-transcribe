#!/bin/bash
set -e

# Audio Extraction Script
# Extracts audio track from video files using ffmpeg
#
# Usage: ./extract-audio.sh <video_file> <output_audio_file>
# 
# Examples:
#   ./extract-audio.sh video.mp4 audio.aac
#   ./extract-audio.sh video.mkv audio.m4a
#
# Dependencies: ffmpeg

# Get the directory where the script was called from (not where it's located)
CALL_DIR="$(pwd)"
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
if [ $# -ne 2 ]; then
  echo "Error: Invalid number of arguments"
  echo "Usage: $0 <video_file> <output_audio_file>"
  echo "Example: $0 video.mp4 audio.aac"
  exit 1
fi

VIDEO_FILE="$1"
OUTPUT_FILE="$2"

# Convert to absolute paths if relative
if [[ "$VIDEO_FILE" != /* ]]; then
  VIDEO_FILE="${CALL_DIR}/${VIDEO_FILE}"
fi
if [[ "$OUTPUT_FILE" != /* ]]; then
  OUTPUT_FILE="${CALL_DIR}/${OUTPUT_FILE}"
fi

# Validate input file exists
if [ ! -f "$VIDEO_FILE" ]; then
  echo "Error: Video file not found: $VIDEO_FILE"
  exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg is not installed"
  exit 1
fi

# Create output directory if needed
output_dir=$(dirname "$OUTPUT_FILE")
mkdir -p "$output_dir"

timestamp=$(date "+%Y.%m.%d-%H:%M:%S")
logs_dir="${CALL_DIR}/logs"
mkdir -p "$logs_dir"

echo "========================================" | tee -a "${logs_dir}/extract-${timestamp}.log"
echo "Audio Extraction (ffmpeg)" | tee -a "${logs_dir}/extract-${timestamp}.log"
echo "Input: $VIDEO_FILE" | tee -a "${logs_dir}/extract-${timestamp}.log"
echo "Output: $OUTPUT_FILE" | tee -a "${logs_dir}/extract-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/extract-${timestamp}.log"

echo "$timestamp - Starting audio extraction" | tee -a "${logs_dir}/extract-${timestamp}.log"

# Extract audio without re-encoding (copy codec)
ffmpeg -i "$VIDEO_FILE" -vn -acodec copy "$OUTPUT_FILE" -loglevel error -stats 2>&1 | tee -a "${logs_dir}/extract-${timestamp}.log"

echo "$timestamp - Audio extraction completed" | tee -a "${logs_dir}/extract-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/extract-${timestamp}.log"
echo "Output saved to: $OUTPUT_FILE" | tee -a "${logs_dir}/extract-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/extract-${timestamp}.log"
