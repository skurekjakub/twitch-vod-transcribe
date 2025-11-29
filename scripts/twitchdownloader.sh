#!/usr/bin/env bash

# Downloads Twitch VOD with chat overlay using TwitchDownloader CLI
# Renders chat as a transparent overlay at 60fps in 1080p60 (or next best quality, NOT 4K)
#
# Usage: vod twitchdownloader [OPTIONS] <VOD_URL_OR_ID>
#
# Examples:
#   vod twitchdownloader https://www.twitch.tv/videos/2588036186
#   vod twitchdownloader 2588036186
#   vod twitchdownloader --quality 720p60 https://www.twitch.tv/videos/2588036186
#
# Dependencies: TwitchDownloaderCLI, ffmpeg

set -euo pipefail

# Get the root directory (parent of scripts/) - can be overridden for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${VOD_ROOT_DIR:-$(dirname "$SCRIPT_DIR")}"
cd "$ROOT_DIR"

# Configuration
QUALITY="${QUALITY:-1080p60}"
FRAMERATE=60
CHAT_WIDTH=360
CHAT_HEIGHT=720
BACKGROUND_COLOR="#00000000"  # Fully transparent
FONT_SIZE=18
OUTPUT_DIR="videos"
LOGS_DIR="logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOGS_DIR"

# Generate timestamp for logging
timestamp=$(date +%Y.%m.%d-%H:%M:%S)
log_file="${LOGS_DIR}/twitchdownloader-${timestamp}.log"

# Logging function
log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" | tee -a "$log_file"
}

# Error handler
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if TwitchDownloaderCLI is available
if ! command -v TwitchDownloaderCLI &> /dev/null; then
    error_exit "TwitchDownloaderCLI not found. Please install TwitchDownloader CLI first."
fi

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    error_exit "ffmpeg not found. Please install ffmpeg first."
fi

# Usage function
usage() {
    cat << EOF
TwitchDownloader - Download VOD with Chat Overlay

Usage: vod twitchdownloader [OPTIONS] <VOD_URL_OR_ID>

Downloads Twitch VOD and renders chat as transparent overlay at 60fps.

Options:
    -q, --quality QUALITY   Video quality (default: 1080p60)
                           Examples: 1080p60, 1080p, 720p60, 720p, 480p
                           Will download highest available if not found
    -w, --chat-width WIDTH  Chat overlay width in pixels (default: 420)
    -h, --chat-height HEIGHT Chat overlay height in pixels (default: 1080)
    -o, --output-dir DIR    Output directory (default: videos)
    --help                  Show this help message

Examples:
    vod twitchdownloader https://www.twitch.tv/videos/2588036186
    vod twitchdownloader 2588036186
    vod twitchdownloader --quality 720p60 https://www.twitch.tv/videos/2588036186
    vod twitchdownloader -w 500 -h 1080 2588036186
    vod td 2588036186                    # Short alias

Output:
    - {VOD_ID}.mp4           Original video
    - {VOD_ID}_chat.json     Chat data with embedded emotes
    - {VOD_ID}_chat.mov      Transparent chat overlay (ProRes)
    - {VOD_ID}_with_chat.mp4 Final video with chat overlay
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quality)
            QUALITY="$2"
            shift 2
            ;;
        -w|--chat-width)
            CHAT_WIDTH="$2"
            shift 2
            ;;
        -h|--chat-height)
            CHAT_HEIGHT="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        -*)
            error_exit "Unknown option: $1. Use --help for usage information."
            ;;
        *)
            VOD_INPUT="$1"
            shift
            ;;
    esac
done

# Validate input
if [ -z "${VOD_INPUT:-}" ]; then
    error_exit "No VOD URL or ID provided. Use --help for usage information."
fi

# Extract VOD ID from URL or use directly if it's an ID
if [[ "$VOD_INPUT" =~ ^https://www\.twitch\.tv/videos/([0-9]+) ]]; then
    VOD_ID="${BASH_REMATCH[1]}"
elif [[ "$VOD_INPUT" =~ ^[0-9]+$ ]]; then
    VOD_ID="$VOD_INPUT"
else
    error_exit "Invalid VOD URL or ID format. Expected: https://www.twitch.tv/videos/ID or just ID"
fi

log "Starting download for VOD ID: $VOD_ID"
log "Quality: $QUALITY"
log "Framerate: ${FRAMERATE}fps"
log "Chat dimensions: ${CHAT_WIDTH}x${CHAT_HEIGHT}"
log "Output directory: $OUTPUT_DIR"

# Define output file names
VIDEO_OUTPUT="${OUTPUT_DIR}/${VOD_ID}.mp4"
CHAT_JSON="${OUTPUT_DIR}/${VOD_ID}_chat.json"
CHAT_RENDER="${OUTPUT_DIR}/${VOD_ID}_chat.mov"
FINAL_OUTPUT="${OUTPUT_DIR}/${VOD_ID}_with_chat.mp4"

# Cleanup function for partial files
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "Cleaning up partial files due to error..."
        rm -f "$VIDEO_OUTPUT" "$CHAT_JSON" "$CHAT_RENDER" "$FINAL_OUTPUT"
    fi
}
trap cleanup EXIT

# Step 1: Download video
log "Step 1/4: Downloading video at quality '$QUALITY'..."
if TwitchDownloaderCLI videodownload \
    --id "$VOD_ID" \
    --quality "$QUALITY" \
    --ffmpeg-path "ffmpeg" \
    -o "$VIDEO_OUTPUT" \
    >> "$log_file" 2>&1; then
    log "✓ Video downloaded successfully: $VIDEO_OUTPUT"
else
    error_exit "Failed to download video. Check log: $log_file"
fi

# Step 2: Download chat with embedded data
log "Step 2/4: Downloading chat with embedded emotes..."
if TwitchDownloaderCLI chatdownload \
    --id "$VOD_ID" \
    -o "$CHAT_JSON" \
    -E \
    --bttv=true \
    --ffz=true \
    --stv=true \
    >> "$log_file" 2>&1; then
    log "✓ Chat downloaded successfully: $CHAT_JSON"
else
    error_exit "Failed to download chat. Check log: $log_file"
fi

# Step 3: Render chat with transparent background
log "Step 3/4: Rendering chat overlay at ${FRAMERATE}fps with transparent background..."
if TwitchDownloaderCLI chatrender \
    -i "$CHAT_JSON" \
    -o "$CHAT_RENDER" \
    -h "$CHAT_HEIGHT" \
    -w "$CHAT_WIDTH" \
    --framerate "$FRAMERATE" \
    --update-rate 0.2 \
    --font-size "$FONT_SIZE" \
    --background-color "$BACKGROUND_COLOR" \
    --outline \
    --sub-messages=true \
    --badges=true \
    --ffmpeg-path "ffmpeg" \
    >> "$log_file" 2>&1; then
    log "✓ Chat rendered successfully: $CHAT_RENDER"
else
    error_exit "Failed to render chat. Check log: $log_file"
fi

# Step 4: Composite chat overlay onto video
log "Step 4/4: Compositing chat overlay onto video..."
if ffmpeg -i "$VIDEO_OUTPUT" -i "$CHAT_RENDER" \
    -filter_complex "[0:v][1:v]overlay=W-w-10:10[v]" \
    -map "[v]" -map 0:a \
    -c:v libx264 -preset fast -crf 18 \
    -c:a copy \
    "$FINAL_OUTPUT" \
    >> "$log_file" 2>&1; then
    log "✓ Final video with chat overlay created: $FINAL_OUTPUT"
else
    error_exit "Failed to composite chat overlay. Check log: $log_file"
fi

# Summary
log ""
log "=========================================="
log "Download and rendering complete!"
log "=========================================="
log "Video: $VIDEO_OUTPUT"
log "Chat JSON: $CHAT_JSON"
log "Chat overlay: $CHAT_RENDER"
log "Final output: $FINAL_OUTPUT"
log "Log file: $log_file"
log ""
log "The chat overlay is positioned at the top-right corner with 10px padding."
log "You can adjust the position by modifying the overlay filter coordinates."
