#!/bin/bash
set -e

# Twitch VOD Transcriber
# Downloads a Twitch VOD and optionally transcribes it to English subtitles
#
# Usage: ./vod-transcribe.sh [--download-only] [--quality QUALITY] <twitch_vod_url>
# 
# Examples:
#   ./vod-transcribe.sh https://www.twitch.tv/videos/2588036186
#   ./vod-transcribe.sh --quality 720p https://www.twitch.tv/videos/2588036186
#   ./vod-transcribe.sh --download-only https://www.twitch.tv/videos/2588036186
#
# Options:
#   --download-only    Only download the video, skip audio extraction and transcription
#   --quality QUALITY  Video quality to download (default: 480p)
#                      Available: 160p, 360p, 480p, 720p, 720p60, 1080p, 1080p60, source
#
# Dependencies: twitch-dl, ffmpeg, faster-whisper
# Models download automatically on first run

cd "$(dirname "$0")"

# Activate Python environment if available
if [ -z "$CONDA_DEFAULT_ENV" ] && [ -f "venv/bin/activate" ]; then
  source venv/bin/activate
fi

# Default values
QUALITY="480p"
DOWNLOAD_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --download-only)
      DOWNLOAD_ONLY=true
      shift
      ;;
    --quality)
      QUALITY="$2"
      shift 2
      ;;
    https://www.twitch.tv/videos/*)
      VOD_URL="$1"
      shift
      ;;
    *)
      echo "Error: Unknown argument: $1"
      echo "Usage: $0 [--download-only] [--quality QUALITY] <twitch_vod_url>"
      echo "Example: $0 --quality 720p https://www.twitch.tv/videos/2588036186"
      echo "Example: $0 --download-only https://www.twitch.tv/videos/2588036186"
      exit 1
      ;;
  esac
done

# Validate URL
if [[ -z "$VOD_URL" ]] || [[ ! "$VOD_URL" =~ ^https://www\.twitch\.tv/videos/[0-9]+$ ]]; then
  echo "Error: Invalid or missing Twitch VOD URL!"
  echo "Usage: $0 [--download-only] [--quality QUALITY] <twitch_vod_url>"
  echo "Example: $0 --quality 720p https://www.twitch.tv/videos/2588036186"
  echo "Example: $0 --download-only https://www.twitch.tv/videos/2588036186"
  exit 1
fi

# Extract VOD ID from URL
VOD_ID=$(echo "$VOD_URL" | grep -oP 'videos/\K\d+')
if [ -z "$VOD_ID" ]; then
  echo "Error: Could not extract VOD ID from URL: $VOD_URL"
  exit 1
fi

timestamp=$(date "+%Y.%m.%d-%H:%M:%S")

# Create directory structures
transcript_dir="transcripts"
logs_dir="logs"
mkdir -p "$transcript_dir" "$logs_dir"

echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Twitch VOD Transcriber" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "VOD ID: $VOD_ID" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "URL: $VOD_URL" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Quality: $QUALITY" | tee -a "${logs_dir}/run-${timestamp}.log"
if [ "$DOWNLOAD_ONLY" = true ]; then
  echo "Mode: Download only" | tee -a "${logs_dir}/run-${timestamp}.log"
fi
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"

# Step 1: Download VOD using twitch-dl
echo "$VOD_ID - $timestamp - Starting download ($QUALITY quality)" | tee -a "${logs_dir}/run-${timestamp}.log"
trap 'echo "$VOD_ID - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred during download. Cleaning up..."; rm -f *"${VOD_ID}"*.mp4' EXIT

# Download at specified quality to current directory
twitch-dl download -q "$QUALITY" "$VOD_URL" --max-workers 3 2>&1 | tee -a "${logs_dir}/run-${timestamp}.log"

# Wait a moment for file system to sync
sleep 2

# Find downloaded file with twitch-dl naming pattern: YYYY-MM-DD_VODID_channel_title.mp4
downloaded_file=$(ls -t *"_${VOD_ID}_"*.mp4 2>/dev/null | head -n 1)
if [ -z "$downloaded_file" ]; then
  echo "$VOD_ID - $timestamp - Error: Could not find downloaded file!" | tee -a "${logs_dir}/run-${timestamp}.log"
  exit 1
fi

echo "$VOD_ID - $timestamp - Found downloaded file: $downloaded_file" | tee -a "${logs_dir}/run-${timestamp}.log"

# Extract components from twitch-dl filename and create organized structure
if [[ "$downloaded_file" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})_${VOD_ID}_([^_]+)_(.+)\.mp4$ ]]; then
  date_part="${BASH_REMATCH[1]}"
  channel_part="${BASH_REMATCH[2]}"
  title_part="${BASH_REMATCH[3]}"
  
  # Create shortened filename: channel-date-firsttwentycharacters
  title_short="${title_part:0:20}"
  title_short="${title_short//_/-}"
  base_name="${channel_part}-${date_part}-${title_short}"
  
  # Create organized directory structures
  vod_dir="vods/${channel_part}"
  transcript_channel_dir="${transcript_dir}/${channel_part}"
  mkdir -p "$vod_dir" "$transcript_channel_dir"
else
  echo "$VOD_ID - $timestamp - Warning: Unexpected filename format, using fallback naming" | tee -a "${logs_dir}/run-${timestamp}.log"
  base_name="${downloaded_file%.mp4}"
  vod_dir="vods/unknown"
  transcript_channel_dir="${transcript_dir}/unknown"
  mkdir -p "$vod_dir" "$transcript_channel_dir"
fi

# Define final file paths
mp4_filename="${vod_dir}/${base_name}.mp4"
audio_filename="${vod_dir}/${base_name}.aac"
srt_filename_en="${transcript_channel_dir}/${base_name}-en.srt"

# Move downloaded file to organized location
mv "$downloaded_file" "$mp4_filename"
echo "$VOD_ID - $timestamp - Moved to: $mp4_filename" | tee -a "${logs_dir}/run-${timestamp}.log"

trap - EXIT
echo "$VOD_ID - $timestamp - Download completed" | tee -a "${logs_dir}/run-${timestamp}.log"

# Exit early if download-only mode
if [ "$DOWNLOAD_ONLY" = true ]; then
  echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
  echo "Download completed! (Download-only mode)" | tee -a "${logs_dir}/run-${timestamp}.log"
  echo "Output file:" | tee -a "${logs_dir}/run-${timestamp}.log"
  echo "  - Video: $mp4_filename" | tee -a "${logs_dir}/run-${timestamp}.log"
  echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
  exit 0
fi

# Step 2: Extract audio from video
echo "$VOD_ID - $timestamp - Starting audio extraction" | tee -a "${logs_dir}/run-${timestamp}.log"
trap 'echo "$VOD_ID - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$audio_filename"' EXIT
ffmpeg -i "$mp4_filename" -vn -acodec copy "$audio_filename" -loglevel error -stats
trap - EXIT
echo "$VOD_ID - $timestamp - Audio extraction completed" | tee -a "${logs_dir}/run-${timestamp}.log"

# Step 3: Transcribe using faster-whisper
echo "$VOD_ID - $timestamp - Starting English transcription with Whisper (large-v3 model)" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "$VOD_ID - $timestamp - This may take a while for long videos..." | tee -a "${logs_dir}/run-${timestamp}.log"
trap 'echo "$VOD_ID - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$srt_filename_en"' EXIT

# Use Python to run faster-whisper
python3 << EOF
from faster_whisper import WhisperModel
import sys
import os

# Use large-v3 model with CUDA acceleration
print("Loading Whisper model (this will download ~3GB on first run)...")
print("Model downloads to: ~/.cache/huggingface/hub/")
model = WhisperModel("large-v3", device="cuda", compute_type="float16")

print("Model loaded. Starting transcription...")
segments, info = model.transcribe(
    "$audio_filename",
    language="en",
    beam_size=5,
    vad_filter=True,  # Voice activity detection to filter silence
    vad_parameters=dict(min_silence_duration_ms=500)
)

print(f"Detected language '{info.language}' with probability {info.language_probability}")

# Write SRT file
with open("$srt_filename_en", "w", encoding="utf-8") as f:
    segment_count = 0
    for segment in segments:
        segment_count += 1
        start_time = segment.start
        end_time = segment.end
        text = segment.text.strip()
        
        f.write(f"{text}\n\n")
        
        if segment_count % 100 == 0:
            print(f"Processed {segment_count} segments...")

print(f"Transcription complete! Generated {segment_count} segments.")
EOF

trap - EXIT
echo "$VOD_ID - $timestamp - English transcription completed" | tee -a "${logs_dir}/run-${timestamp}.log"

# Summary
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Processing completed successfully!" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "Output files:" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "  - Video: $mp4_filename" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "  - Audio (AAC): $audio_filename" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "  - Transcript: $srt_filename_en" | tee -a "${logs_dir}/run-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/run-${timestamp}.log"
