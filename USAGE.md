# Usage Guide

## Quick Start

The `vod` CLI provides a unified interface for all video download and transcription operations.

```bash
# See all available commands
./vod --help

# Get help for a specific command
./vod download --help
./vod batch transcribe --help
```

---

## Twitch VOD Transcription

### Quick Start

```bash
./vod transcribe https://www.twitch.tv/videos/2588036186
```

This will:
1. Download the VOD at 480p (optimal for audio extraction)
2. Extract audio using `lib/extract-audio.sh`
3. Transcribe to plain text using **Whisper large-v3**

### Options

```bash
# Download only (skip transcription)
./vod transcribe --download-only https://www.twitch.tv/videos/2588036186

# Custom video quality
./vod transcribe --quality 720p https://www.twitch.tv/videos/2588036186
```

### Output Files

- `vods/{channel}/{channel}-{date}-{title}.mp4` - downloaded video
- `vods/{channel}/{channel}-{date}-{title}.aac` - extracted audio
- `transcripts/{channel}/{channel}-{date}-{title}-en.txt` - plain text transcript

---

## YouTube Video Transcription

### Quick Start

```bash
# Fetch existing captions (fastest)
./vod youtube https://www.youtube.com/watch?v=VIDEO_ID

# Download audio and transcribe if no captions available
./vod youtube --download https://www.youtube.com/watch?v=VIDEO_ID
```

### Options

```bash
# Specify caption language
./vod youtube --lang es https://www.youtube.com/watch?v=VIDEO_ID

# List available captions
yt-dlp --list-subs https://www.youtube.com/watch?v=VIDEO_ID
```

### Output Files

- `transcripts/youtube/{channel}-{date}-{title}-{lang}.txt` - plain text transcript
- `vods/youtube/{channel}-{date}-{title}.m4a` - audio file (if --download)

---

## Video Downloading

### Single Video

```bash
# Download with chapter splitting
./vod download https://www.youtube.com/watch?v=VIDEO_ID
./vod download https://www.twitch.tv/videos/12345

# With optional filename prefix
./vod download https://youtu.be/xyz my-prefix
```

Features:
- Automatic chapter splitting with sanitized filenames
- Auto-split videos >6 hours into 5-hour chunks
- H.264/AAC codec selection for TV compatibility
- NAS detection for automatic path routing

### Batch Downloading

```bash
./vod batch download              # Process urls-vods (default)
./vod batch download my-list.txt  # Custom file
./vod batch download --continue-on-error
```

### URL File Format (`urls-vods`)

Supports optional prefixes to organize files:

```text
# Comments start with #
https://www.twitch.tv/videos/123456789
https://youtu.be/abcdefg my-prefix
https://www.youtube.com/watch?v=xyz123 archive-2025
```

- **No prefix**: Saved as `{date}-{title}.mp4`
- **With prefix**: Saved as `{prefix}-{date}-{title}.mp4`

---

## Batch Transcription

Process multiple URLs from a file:

```bash
./vod batch transcribe                      # Process urls.txt (default)
./vod batch transcribe my-urls.txt          # Custom file
./vod batch transcribe --quality 720p       # Higher quality Twitch
./vod batch transcribe --download-youtube   # Force YouTube transcription
./vod batch transcribe --continue-on-error  # Don't stop on failure
```

### URL File Format (`urls.txt`)

```text
# Comments start with #
https://www.twitch.tv/videos/2588036186
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://youtu.be/jNQXAC9IVRw

# Blank lines are ignored
```

The batch script:
- Auto-detects URL type (Twitch/YouTube)
- For YouTube: tries captions first, auto-falls back to audio transcription
- Tracks progress with `[X/Y]` format
- Logs to `logs/batch-{timestamp}.log`

---

## Listing Twitch VODs

```bash
./vod list forsen                          # Human-readable list
./vod list forsen --urls-only              # Just URLs (for piping)
./vod list forsen --limit 10               # Last 10 VODs
./vod list forsen --chapters               # Include chapter info
./vod list forsen --urls-only >> urls-vods # Add to download queue
```

---

## Video Splitting

Split long videos into chunks:

```bash
./vod split video.mp4              # 5-hour chunks (default)
./vod split video.mp4 3            # 3-hour chunks
```

---

## TwitchDownloader (Chat Overlay)

Download VODs with chat overlay using TwitchDownloaderCLI:

```bash
./vod twitchdownloader https://www.twitch.tv/videos/2588036186
./vod twitchdownloader --quality 720p60 2588036186
./vod td -w 500 -h 1080 2588036186    # Short alias
```

Output files:
- `{VOD_ID}.mp4` - Original video
- `{VOD_ID}_chat.json` - Chat data with emotes
- `{VOD_ID}_chat.mov` - Transparent chat overlay
- `{VOD_ID}_with_chat.mp4` - Final video with chat

---

## Web Interface

Start a browser-based UI for managing queues:

```bash
./vod web
```

Opens at **http://localhost:8080** with:

- **Status bar** - Shows NAS mount status and GPU availability
- **Download queue** - View/manage `urls-vods` file
- **Transcribe queue** - View/manage `urls.txt` file
- **Add URLs** - Paste URL + optional prefix
- **Remove URLs** - One-click removal from queue
- **Auto-refresh** - Updates every 30 seconds

The web interface directly reads/writes the same queue files used by the CLI, so changes are immediately reflected in both.

---

## NAS Configuration

The project supports automatic downloading to a Network Attached Storage (NAS) via CIFS/SMB.

### Setup

1. Create a `.env.local` file in the project root:
   ```bash
   NAS_HOST="192.168.1.XX"      # IP address of your NAS
   NAS_SHARE="share_name"       # Share name (e.g., "video", "public")
   NAS_USER="your_username"     # SMB username
   NAS_PASS="your_password"     # SMB password
   ```

2. Rebuild the dev container. The NAS will be automatically mounted at `/nas`.

### Behavior

- **If NAS is mounted**: Videos are downloaded to `/nas/vods/{channel_name}/`.
- **If NAS is NOT mounted**: Videos are downloaded to the local `videos/` directory.

### Unmount

To unmount the NAS at `/nas`:

```bash
./vod unmount-nas
```

---

## Library Scripts (Advanced)

The following helper scripts are located in `lib/` and can be used standalone:

### Extract Audio from Video

```bash
./lib/extract-audio.sh input-video.mp4 output-audio.aac
```

Uses ffmpeg to extract audio track without re-encoding.

### Transcribe Audio to Text

```bash
./lib/transcribe-audio.sh input-audio.m4a output-transcript.txt
```

Uses Whisper large-v3 model with CUDA acceleration to transcribe audio to plain text.

---

## Requirements

### System Dependencies
- **ffmpeg** - for audio/video processing
  ```bash
  sudo apt install ffmpeg
  ```
- **CUDA** (optional but recommended) - for GPU-accelerated transcription
  - With CUDA: ~30-60 min for 4-hour VOD
  - Without CUDA: ~2-4 hours for 4-hour VOD

### Python Dependencies
```bash
pip install -r requirements.txt  # Installs faster-whisper, twitch-dl, yt-dlp
```

### Whisper Models
The script uses **OpenAI Whisper large-v3** model which provides:
- ✅ High-quality transcription with proper punctuation and capitalization
- ✅ Better handling of gaming/streaming terminology
- ✅ Automatic language detection
- ✅ Models download automatically on first run (~3GB)
- ✅ Cached in `~/.cache/huggingface/hub/`

Available models (can be changed in `lib/transcribe-audio.sh`):
- `tiny` - Fastest, lowest accuracy (~1GB VRAM)
- `base` - Fast, decent accuracy (~1GB VRAM)
- `small` - Good balance (~2GB VRAM)
- `medium` - Better quality (~5GB VRAM)
- `large-v2` - Excellent quality (~10GB VRAM)
- `large-v3` - **Best quality** (~10GB VRAM) - **Default**

---

## GPU Acceleration

The transcription script automatically uses CUDA if available:
- **RTX A2000 (8GB VRAM)**: Can run `large-v3` with `float16`
- **Lower VRAM GPUs**: Edit `lib/transcribe-audio.sh` to use `medium` or `small` models
- **CPU-only systems**: Falls back to CPU (slower but works)

To modify GPU settings, edit `lib/transcribe-audio.sh`:
```python
# Change model size:
model = WhisperModel("medium", device="cuda", compute_type="float16")

# For CPU only:
model = WhisperModel("medium", device="cpu", compute_type="int8")
```

---

## Directory Structure

```
twitch-vod-transcribe/
├── vod                            # Main CLI entrypoint
├── scripts/                       # Command implementations
│   ├── download.sh                # vod download
│   ├── transcribe.sh              # vod transcribe
│   ├── youtube.sh                 # vod youtube
│   ├── list.sh                    # vod list
│   ├── batch-download.sh          # vod batch download
│   ├── batch-transcribe.sh        # vod batch transcribe
│   ├── split.sh                   # vod split
│   └── twitchdownloader.sh        # vod twitchdownloader
├── web/                           # Web interface
│   └── app.py                     # FastAPI app (vod web)
├── lib/                           # Shared helper scripts
│   ├── extract-audio.sh           # Extract audio from video (ffmpeg)
│   └── transcribe-audio.sh        # Transcribe audio to text (Whisper)
├── python/                        # Python utilities
│   ├── download_vod.py            # Standalone Twitch downloader
│   └── maya_tts.py                # TTS utility
├── vods/                          # Downloaded videos/audio
│   ├── {channel}/                 # Twitch VODs organized by channel
│   └── youtube/                   # YouTube videos/audio
├── transcripts/                   # All transcripts (plain text)
│   ├── {channel}/                 # Twitch transcripts by channel
│   └── youtube/                   # YouTube transcripts
├── videos/                        # TwitchDownloader outputs
├── summaries/                     # AI-generated summaries
└── logs/                          # Execution logs
```
