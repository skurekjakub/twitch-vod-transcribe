#!/bin/bash
# shellcheck disable=SC1083

set -e

# This script downloads a Twitch VOD and transcribes it to English subtitles using OpenAI Whisper.
#
# Usage:
# ./vod-transcribe-whisper.sh <twitch_vod_url>
#
# Example:
# ./vod-transcribe-whisper.sh https://www.twitch.tv/videos/2588036186
#
# Dependencies:
# - twitch-dl (pip install twitch-dl)
# - ffmpeg
# - openai-whisper (pip install openai-whisper)
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
echo "Twitch VOD Transcriber (OpenAI Whisper)" | tee -a run-"$timestamp".log
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

# Step 3: Transcribe using OpenAI Whisper
# English transcription
if [ ! -f "$srt_filename_en" ]; then
  echo "$VOD_ID - $timestamp - Starting English transcription with OpenAI Whisper (medium model)" | tee -a run-"$timestamp".log
  echo "$VOD_ID - $timestamp - This may take a while for long videos..." | tee -a run-"$timestamp".log
  trap 'echo "$VOD_ID - $(date "+%Y.%m.%d-%H:%M:%S") - An error occurred. Deleting current file..."; rm -f "$srt_filename_en"' EXIT
  
  # Use Python to run OpenAI Whisper
  python3 << EOF
import whisper
import sys
import os

# Use medium model - optimal for 8GB GPU
# Model sizes: tiny (~1GB VRAM), base (~1GB VRAM), small (~2GB VRAM), 
#              medium (~5GB VRAM), large (~10GB VRAM)
# Medium is the best balance for 8GB GPU with room for processing overhead
print("Loading OpenAI Whisper model (medium)...")
print("This will download ~1.5GB on first run to ~/.cache/whisper/")
model = whisper.load_model("medium", device="cuda")

print("Model loaded. Starting transcription...")
print("Processing: $audio_filename")

# Transcribe with word-level timestamps for better SRT formatting
result = model.transcribe(
    "$audio_filename",
    language="en",
    task="transcribe",
    verbose=True,
    fp16=True  # Use half precision for better performance on GPU
)

print(f"Detected language: {result['language']}")

# Write SRT file
with open("$srt_filename_en", "w", encoding="utf-8") as f:
    for i, segment in enumerate(result['segments'], start=1):
        # Format timestamps as HH:MM:SS,mmm (SRT format)
        def format_timestamp(seconds):
            hours = int(seconds // 3600)
            minutes = int((seconds % 3600) // 60)
            secs = int(seconds % 60)
            millis = int((seconds % 1) * 1000)
            return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"
        
        start_time = format_timestamp(segment['start'])
        end_time = format_timestamp(segment['end'])
        text = segment['text'].strip()
        
        # Write SRT entry
        f.write(f"{i}\n")
        f.write(f"{start_time} --> {end_time}\n")
        f.write(f"{text}\n\n")

print(f"Transcription complete! Generated {len(result['segments'])} segments.")
print(f"Output saved to: $srt_filename_en")
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
