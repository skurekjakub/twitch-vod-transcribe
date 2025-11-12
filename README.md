# Twitch & YouTube VOD Transcriber

Download and transcribe Twitch VODs and YouTube videos using OpenAI's Whisper model (via `faster-whisper`).

## Quick Start

### Twitch VODs
1. Clone this repo.
2. `pip install -r requirements.txt`
3. Run: `./vod-transcribe.sh https://www.twitch.tv/videos/YOUR_VOD_ID`

### YouTube Videos
1. Install yt-dlp: `pip install yt-dlp`
2. Run: `./youtube-transcript-ytdlp.sh https://www.youtube.com/watch?v=VIDEO_ID`
3. Or download + transcribe: `./youtube-transcript-ytdlp.sh --download https://www.youtube.com/watch?v=VIDEO_ID`

See [USAGE.md](USAGE.md) for detailed instructions and options.

## Project Structure
```
.
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
- **`vod-transcribe.sh`**: Twitch VOD pipeline - downloads VOD, extracts audio, transcribes to text
- **`youtube-transcript-ytdlp.sh`**: YouTube pipeline - fetches captions or downloads/transcribes audio
- **`download_vod.py`**: Standalone Twitch VOD downloader

### Library Scripts
- **`lib/extract-audio.sh`**: Extracts audio track from video files using ffmpeg
- **`lib/transcribe-audio.sh`**: Transcribes audio to plain text using Whisper (CUDA-accelerated)

### Dependencies
- `requirements.txt`: Core Python dependencies (`faster-whisper`, `twitch-dl`)
- Additional: `yt-dlp` for YouTube downloads

## Features
- ✅ High-quality transcription using Whisper large-v3 model
- ✅ CUDA GPU acceleration support (RTX A2000 tested)
- ✅ Organized output by channel and date
- ✅ YouTube subtitle fetching (no API key required)
- ✅ Automatic audio extraction and transcription fallback
- ✅ Modular architecture with reusable components
