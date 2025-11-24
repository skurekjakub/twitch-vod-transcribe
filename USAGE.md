# Usage Guide

## Twitch VOD Transcription

### Quick Start

Use the `vod-transcribe.sh` script to download and transcribe in one command:

```bash
./vod-transcribe.sh https://www.twitch.tv/videos/2588036186
```

This script will:
1. Download the VOD at 480p (optimal for audio extraction)
2. Extract audio from the video using `lib/extract-audio.sh`
3. Transcribe to plain text using **Whisper large-v3** with `lib/transcribe-audio.sh`

### Options

```bash
# Download only (skip transcription)
./vod-transcribe.sh --download-only https://www.twitch.tv/videos/2588036186

# Custom video quality
./vod-transcribe.sh --quality 720p https://www.twitch.tv/videos/2588036186
```

### Output Files

After processing, you'll have:
- `vods/{channel}/{channel}-{date}-{title}.mp4` - downloaded video
- `vods/{channel}/{channel}-{date}-{title}.aac` - extracted audio
- `transcripts/{channel}/{channel}-{date}-{title}-en.txt` - plain text transcript

---

## YouTube Video Transcription

### Quick Start

Use the `youtube-transcript-ytdlp.sh` script to fetch transcripts from YouTube:

```bash
# Fetch existing captions (fastest)
./youtube-transcript-ytdlp.sh https://www.youtube.com/watch?v=VIDEO_ID

# Download audio and transcribe if no captions available
./youtube-transcript-ytdlp.sh --download https://www.youtube.com/watch?v=VIDEO_ID

# Download video, extract audio, and transcribe
./youtube-transcript-ytdlp.sh --download-video https://www.youtube.com/watch?v=VIDEO_ID
```

### Options

```bash
# Specify caption language
./youtube-transcript-ytdlp.sh --lang es https://www.youtube.com/watch?v=VIDEO_ID

# Download audio-only (m4a format)
./youtube-transcript-ytdlp.sh --download https://www.youtube.com/watch?v=VIDEO_ID

# Download video (lowest quality), extract audio, transcribe
./youtube-transcript-ytdlp.sh --download-video https://www.youtube.com/watch?v=VIDEO_ID

# List available captions
yt-dlp --list-subs https://www.youtube.com/watch?v=VIDEO_ID
```

### Output Files

- `transcripts/youtube/{channel}-{date}-{title}-{lang}.txt` - plain text transcript
- `vods/youtube/{channel}-{date}-{title}.m4a` - audio file (if --download)
- `vods/youtube/{channel}-{date}-{title}.mp4` - video file (if --download-video)
- `vods/youtube/{channel}-{date}-{title}.aac` - extracted audio (if --download-video)

---

## Batch Video Downloading

Use `batch-download.sh` to download multiple videos without transcription. This is useful for archiving content to your NAS.

### Usage

```bash
./batch-download.sh [url_file]
```

### URL File Format (`urls-vods`)

Supports optional prefixes to organize files:

```text
https://www.twitch.tv/videos/123456789
https://youtu.be/abcdefg my-prefix
https://www.youtube.com/watch?v=xyz123 archive-2025
```

- **No prefix**: Saved as `{channel}-{date}-{title}.mp4`
- **With prefix**: Saved as `{prefix}-{channel}-{date}-{title}.mp4`

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
pip install -r requirements.txt  # Installs faster-whisper, twitch-dl
pip install yt-dlp              # For YouTube downloads
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
├── vod-transcribe.sh              # Twitch VOD downloader + transcriber
├── youtube-transcript-ytdlp.sh    # YouTube transcript fetcher + transcriber
├── download_vod.py                # Standalone Twitch VOD downloader
├── lib/                           # Helper scripts
│   ├── extract-audio.sh           # Extract audio from video (ffmpeg)
│   └── transcribe-audio.sh        # Transcribe audio to text (Whisper)
├── vods/                          # Downloaded videos/audio
│   ├── {channel}/                 # Twitch VODs organized by channel
│   └── youtube/                   # YouTube videos/audio
├── transcripts/                   # All transcripts (plain text)
│   ├── {channel}/                 # Twitch transcripts by channel
│   └── youtube/                   # YouTube transcripts
├── summaries/                     # AI-generated summaries
└── logs/                          # Execution logs
```
