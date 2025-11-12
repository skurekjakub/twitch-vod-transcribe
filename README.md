# Twitch & YouTube VOD Transcriber

Download and transcribe Twitch VODs and YouTube videos using OpenAI's Whisper model (via `faster-whisper`).

## Quick Start

### Single Video Processing

#### Twitch VODs
1. Clone this repo.
2. `pip install -r requirements.txt`
3. Run: `./vod-transcribe.sh https://www.twitch.tv/videos/YOUR_VOD_ID`

#### YouTube Videos
1. Install yt-dlp: `pip install yt-dlp`
2. Run: `./youtube-transcript-ytdlp.sh https://www.youtube.com/watch?v=VIDEO_ID`
   - Fetches captions if available (fast)
   - Automatically downloads and transcribes if no captions exist

### Batch Processing (Recommended)
Process multiple URLs from a file:

1. Create `urls.txt` with one URL per line (supports both Twitch and YouTube)
2. Run: `./batch-transcribe.sh`

```bash
# Example urls.txt
https://www.twitch.tv/videos/2588036186
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://youtu.be/jNQXAC9IVRw
```

The batch script:
- Auto-detects URL type (Twitch/YouTube)
- Tries caption fetch first for YouTube (fast)
- **Automatically falls back to audio download + transcription if no captions**
- Processes sequentially with progress tracking
- Continues on errors with `--continue-on-error`

See [USAGE.md](USAGE.md) for detailed instructions and options.

## Project Structure
```
.
├── batch-transcribe.sh            # Batch processor for multiple URLs
├── vod-transcribe.sh              # Twitch VOD downloader + transcriber
├── youtube-transcript-ytdlp.sh    # YouTube transcript fetcher + transcriber
├── download_vod.py                # Standalone VOD downloader
├── lib/                           # Helper scripts
│   ├── extract-audio.sh           # Extract audio from video (ffmpeg)
│   └── transcribe-audio.sh        # Transcribe audio to text (Whisper)
├── transcripts/                   # Output transcripts (txt)
├── vods/                          # Downloaded videos/audio
├── summaries/                     # AI-generated summaries
└── logs/                          # Execution logs
```

## Key Components

### Entry Points
- **`batch-transcribe.sh`**: Batch processor - reads URLs from file, auto-detects type, routes to appropriate script
- **`vod-transcribe.sh`**: Twitch VOD pipeline - downloads VOD, extracts audio, transcribes to text
- **`youtube-transcript-ytdlp.sh`**: YouTube pipeline - fetches captions OR downloads/transcribes audio
- **`download_vod.py`**: Standalone Twitch VOD downloader

### Library Scripts
- **`lib/extract-audio.sh`**: Extracts audio track from video files using ffmpeg
- **`lib/transcribe-audio.sh`**: Transcribes audio to plain text using Whisper (CUDA-accelerated)

### Dependencies
- `requirements.txt`: Core Python dependencies (`faster-whisper`, `twitch-dl`)
- Additional: `yt-dlp` for YouTube downloads

## Features
- ✅ **Batch processing** - Process 3-5 videos daily from a simple URL list
- ✅ **Auto-detection** - Recognizes Twitch and YouTube URLs automatically
- ✅ **Smart fallback** - YouTube captions first, auto-downloads if unavailable
- ✅ High-quality transcription using Whisper large-v3 model
- ✅ CUDA GPU acceleration support (RTX A2000 tested)
- ✅ Organized output by channel and date
- ✅ YouTube subtitle fetching (no API key required)
- ✅ Modular architecture with reusable components
