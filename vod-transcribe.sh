#!/bin/bash
# shellcheck disable=SC1083

set -e

# This script downloads a Twitch VOD and transcribes it to English subtitles.
#
# Usage:
# ./vod-transcribe.sh <twitch_vod_url>
#
# Example:
# ./vod-transcribe.sh https://www.twitch.tv/videos/2588036186
#
# Dependencies:
# - twitch-dl (pip install twitch-dl)
# - ffmpeg
# - faster-whisper (pip install faster-whisper)
# Models download automatically on first run

cd "$(dirname "$0")"

# Check if running in conda environment, otherwise try venv
if [ -z "$CONDA_DEFAULT_ENV" ]; then
  if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
  fi
fi

VOD_URL=""

# Parse arguments
for arg in "$@"; do
  if [[ "$arg" == https://www.twitch.tv/videos/* ]]; then
    VOD_URL="$arg"
  fi
done

# Check if URL was provided
if [ -z "$VOD_URL" ]; then
  echo "Error: No Twitch VOD URL provided!"
  echo "Usage: $0 <twitch_vod_url>"
  echo "Example: $0 https://www.twitch.tv/videos/2588036186"
  exit 1
fi

# Extract VOD ID from URL
VOD_ID=$(echo "$VOD_URL" | grep -oP 'videos/\K\d+')
if [ -z "$VOD_ID" ]; then
  echo "Error: Could not extract VOD ID from URL: $VOD_URL"
  exit 1
fi

timestamp=$(date "+%Y.%m.%d-%H:%M:%S")
echo "========================================" | tee -a run-"$timestamp".log
echo "Twitch VOD Transcriber" | tee -a run-"$timestamp".log
echo "VOD ID: $VOD_ID" | tee -a run-"$timestamp".log
echo "URL: $VOD_URL" | tee -a run-"$timestamp".log
echo "========================================" | tee -a run-"$timestamp".log

# Create transcripts directory structure
transcript_dir="transcripts/${VOD_ID}"
mkdir -p "$transcript_dir"

# Define filenames
mp4_filename="${VOD_ID}.mp4"
audio_filename="${VOD_ID}.aac"
srt_filename_en="${transcript_dir}/${VOD_ID}-en.srt"

# Step 1: Download VOD using twitch-dl
if [ ! -f "$mp4_filename" ]; then
  echo "$VOD_ID - $timestamp - Starting download (480p quality)" | tee -a run-"$timestamp".log
  trap 'echo "$VOD_ID - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred during download. Cleaning up..."; rm -f "$mp4_filename" *"${VOD_ID}"*.mp4' EXIT
  
  # Download at 480p quality (sufficient for audio) to current directory
  # --keep keeps the downloaded chunks (they'll be in .cache anyway)
  twitch-dl download -q 480p "$VOD_URL" 2>&1 | tee -a run-"$timestamp".log
  
  # Wait a moment for file system to sync
  sleep 2
  
  # twitch-dl saves with a different naming pattern, find and rename it
  # Pattern: YYYY-MM-DD_VODID_*_*.mp4
  downloaded_file=$(ls -t *"_${VOD_ID}_"*.mp4 2>/dev/null | head -n 1)
  if [ -z "$downloaded_file" ]; then
    # Try alternative pattern
    downloaded_file=$(ls -t *"${VOD_ID}"*.mp4 2>/dev/null | head -n 1)
  fi
  
  if [ -n "$downloaded_file" ]; then
    echo "$VOD_ID - $timestamp - Found downloaded file: $downloaded_file" | tee -a run-"$timestamp".log
    if [ "$downloaded_file" != "$mp4_filename" ]; then
      mv "$downloaded_file" "$mp4_filename"
      echo "$VOD_ID - $timestamp - Renamed to: $mp4_filename" | tee -a run-"$timestamp".log
    fi
  else
    echo "$VOD_ID - $timestamp - Error: Could not find downloaded file!" | tee -a run-"$timestamp".log
    exit 1
  fi
  
  trap - EXIT
  echo "$VOD_ID - $timestamp - Download completed" | tee -a run-"$timestamp".log
else
  echo "$VOD_ID - $timestamp - Detected existing $mp4_filename. Skipping download." | tee -a run-"$timestamp".log
fi

# Step 2: Extract audio from video
if [ ! -f "$audio_filename" ]; then
  echo "$VOD_ID - $timestamp - Starting audio extraction" | tee -a run-"$timestamp".log
  trap 'echo "$VOD_ID - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$audio_filename"' EXIT
  ffmpeg -i "$mp4_filename" -vn -acodec copy "$audio_filename" -loglevel error -stats
  trap - EXIT
  echo "$VOD_ID - $timestamp - Audio extraction completed" | tee -a run-"$timestamp".log
else
  echo "$VOD_ID - $timestamp - Detected existing $audio_filename. Skipping extraction." | tee -a run-"$timestamp".log
fi

# Step 3: Transcribe using faster-whisper
# English transcription
if [ ! -f "$srt_filename_en" ]; then
  echo "$VOD_ID - $timestamp - Starting English transcription with Whisper (medium model)" | tee -a run-"$timestamp".log
  echo "$VOD_ID - $timestamp - This may take a while for long videos..." | tee -a run-"$timestamp".log
  trap 'echo "$VOD_ID - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$srt_filename_en"' EXIT
  
  # Use Python to run faster-whisper
  python3 << EOF
from faster_whisper import WhisperModel
import sys
import os

# Use large-v3 model with CUDA acceleration
# Options: tiny, base, small, medium, large-v2, large-v3
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
        # SRT format: index, timestamp, text
        start_time = segment.start
        end_time = segment.end
        text = segment.text.strip()
        
        # Format timestamps as HH:MM:SS,mmm
        def format_timestamp(seconds):
            hours = int(seconds // 3600)
            minutes = int((seconds % 3600) // 60)
            secs = int(seconds % 60)
            millis = int((seconds % 1) * 1000)
            return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"
        
        f.write(f"{text}\n\n")
        
        if segment_count % 100 == 0:
            print(f"Processed {segment_count} segments...")

print(f"Transcription complete! Generated {segment_count} segments.")
EOF
  
  trap - EXIT
  echo "$VOD_ID - $timestamp - English transcription completed" | tee -a run-"$timestamp".log
else
  echo "$VOD_ID - $timestamp - Detected existing $srt_filename_en. Skipping English transcription." | tee -a run-"$timestamp".log
fi

# Summary
echo "========================================" | tee -a run-"$timestamp".log
echo "Processing completed successfully!" | tee -a run-"$timestamp".log
echo "Output files:" | tee -a run-"$timestamp".log
echo "  - Video: $mp4_filename" | tee -a run-"$timestamp".log
echo "  - Audio (AAC): $audio_filename" | tee -a run-"$timestamp".log
echo "  - Transcripts: $transcript_dir/" | tee -a run-"$timestamp".log
echo "    - English subtitles: ${VOD_ID}-en.srt" | tee -a run-"$timestamp".log
echo "========================================" | tee -a run-"$timestamp".log
