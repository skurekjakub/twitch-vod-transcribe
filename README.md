# Twitch VOD Transcriber

Download and transcribe Twitch VODs using OpenAI's Whisper model (via `faster-whisper`).

## Quick Start
1. Clone this repo.
2. `pip install -r requirements.txt`
3. Run: `./vod-transcribe.sh https://www.twitch.tv/videos/YOUR_VOD_ID`

See [USAGE.md](USAGE.md) for detailed instructions and options.

## Key Components
- `vod-transcribe.sh`: Main script - downloads VOD, extracts audio, and transcribes to SRT subtitles
- `download_vod.py`: Standalone VOD downloader
- `requirements.txt`: Python dependencies (`faster-whisper`, `twitch-dl`)

## Features
- ✅ High-quality transcription using Whisper large-v3 model
- ✅ CUDA GPU acceleration support
- ✅ Organized output by channel and date
- ✅ Automatic subtitle generation
