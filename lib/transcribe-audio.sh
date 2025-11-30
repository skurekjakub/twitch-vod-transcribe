#!/bin/bash
set -e

# Audio Transcription Script
# Transcribes audio files to plain text using faster-whisper
#
# Usage: ./transcribe-audio.sh [--small|--medium] <audio_file> <output_txt_file>
# 
# Examples:
#   ./transcribe-audio.sh audio.aac transcript.txt          # Uses large-v3 (default)
#   ./transcribe-audio.sh --small audio.aac transcript.txt  # Uses small model (faster, less accurate)
#   ./transcribe-audio.sh --medium audio.aac transcript.txt # Uses medium model (balanced)
#
# Dependencies: faster-whisper (Python package)
# Models download automatically on first run (~3GB for large-v3, ~500MB for small)

# Get the directory where the script was called from (not where it's located)
CALL_DIR="$(pwd)"
# Get the directory where this script is located
# shellcheck disable=SC2034  # SCRIPT_DIR kept for potential future use
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Default model
WHISPER_MODEL="large-v3"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --large)
      WHISPER_MODEL="large-v1"
      shift
      ;;
    --medium)
      WHISPER_MODEL="medium.en"
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [ $# -ne 2 ]; then
  echo "Error: Invalid number of arguments"
  echo "Usage: $0 [--small|--medium] <audio_file> <output_txt_file>"
  echo "Example: $0 audio.aac transcript.txt"
  echo "Example: $0 --small audio.aac transcript.txt"
  exit 1
fi

AUDIO_FILE="$1"
OUTPUT_FILE="$2"

# Convert to absolute paths if relative
if [[ "$AUDIO_FILE" != /* ]]; then
  AUDIO_FILE="${CALL_DIR}/${AUDIO_FILE}"
fi
if [[ "$OUTPUT_FILE" != /* ]]; then
  OUTPUT_FILE="${CALL_DIR}/${OUTPUT_FILE}"
fi

# Validate input file exists
if [ ! -f "$AUDIO_FILE" ]; then
  echo "Error: Audio file not found: $AUDIO_FILE"
  exit 1
fi

# Create output directory if needed
output_dir=$(dirname "$OUTPUT_FILE")
mkdir -p "$output_dir"

timestamp=$(date "+%Y.%m.%d-%H:%M:%S")
logs_dir="${CALL_DIR}/logs"
mkdir -p "$logs_dir"

echo "========================================" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "Audio Transcription (faster-whisper)" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "Model: $WHISPER_MODEL" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "Input: $AUDIO_FILE" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "Output: $OUTPUT_FILE" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/transcribe-${timestamp}.log"

echo "$timestamp - Starting transcription with Whisper ($WHISPER_MODEL model)" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "$timestamp - This may take a while for long audio files..." | tee -a "${logs_dir}/transcribe-${timestamp}.log"

# Use Python to run faster-whisper
python3 << EOF
from faster_whisper import WhisperModel
import sys
import os

# Use specified model with CUDA acceleration
model_name = "$WHISPER_MODEL"
print(f"Loading Whisper model: {model_name}")
print("Model downloads to: ~/.cache/huggingface/hub/")
model = WhisperModel(model_name, device="cuda", compute_type="float16")

print("Model loaded. Starting transcription...")
segments, info = model.transcribe(
    "$AUDIO_FILE",
    language="en",
    beam_size=5,
    vad_filter=True,  # Voice activity detection to filter silence
    vad_parameters=dict(min_silence_duration_ms=500)
)

print(f"Detected language '{info.language}' with probability {info.language_probability}")

# Write plain text file (no timestamps)
with open("$OUTPUT_FILE", "w", encoding="utf-8") as f:
    segment_count = 0
    for segment in segments:
        segment_count += 1
        text = segment.text.strip()
        
        # Write text with double newline separator (matching existing format)
        f.write(f"{text}\n\n")
        
        if segment_count % 100 == 0:
            print(f"Processed {segment_count} segments...")

print(f"Transcription complete! Generated {segment_count} segments.")
EOF

echo "$timestamp - Transcription completed" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "Output saved to: $OUTPUT_FILE" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
echo "========================================" | tee -a "${logs_dir}/transcribe-${timestamp}.log"
