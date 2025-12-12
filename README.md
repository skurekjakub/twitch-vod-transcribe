# Twitch & YouTube VOD Transcriber

A unified CLI tool for downloading and transcribing Twitch VODs and YouTube videos using OpenAI's Whisper model (via `faster-whisper`).

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Download a video with chapters
./vod download https://www.youtube.com/watch?v=VIDEO_ID

# Transcribe a Twitch VOD
./vod transcribe https://www.twitch.tv/videos/YOUR_VOD_ID

# Fetch YouTube captions (or transcribe if unavailable)
./vod youtube https://www.youtube.com/watch?v=VIDEO_ID

# List available VODs for a Twitch channel
./vod list forsen --limit 10

# Show all available commands
./vod --help
```

## Commands

### `vod download <url> [prefix]`
Download video with automatic chapter splitting and NAS support.
```bash
./vod download https://www.youtube.com/watch?v=dQw4w9WgXcQ
./vod download https://www.twitch.tv/videos/12345 my-prefix
```
Features:
- Automatic chapter splitting with sanitized filenames
- Auto-split videos >6 hours into 5-hour chunks
- H.264/AAC codec selection for TV compatibility
- NAS detection: saves to `/nas/vods/<channel>/` if available

### `vod unmount-nas`
Unmount the NAS mount at `/nas` (if mounted).
```bash
./vod unmount-nas
```

### `vod transcribe <url>`
Download and transcribe Twitch VODs using twitch-dl + faster-whisper.
```bash
./vod transcribe https://www.twitch.tv/videos/2588036186
./vod transcribe --quality 720p https://www.twitch.tv/videos/2588036186
./vod transcribe --download-only https://www.twitch.tv/videos/2588036186
```

### `vod youtube <url>`
Fetch YouTube captions or transcribe with Whisper.
```bash
./vod youtube https://www.youtube.com/watch?v=dQw4w9WgXcQ
./vod youtube --download https://www.youtube.com/watch?v=dQw4w9WgXcQ
./vod youtube --lang es https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

### `vod list <channel>`
List available VODs for a Twitch channel.
```bash
./vod list forsen                          # Human-readable list
./vod list forsen --urls-only              # Just URLs (for piping)
./vod list forsen --limit 10               # Last 10 VODs
./vod list forsen --chapters               # Include chapter info
./vod list forsen --urls-only >> urls-vods # Add to download queue
```

### `vod batch download [file]`
Batch download videos from a URL file.
```bash
./vod batch download                       # Process urls-vods
./vod batch download my-urls.txt           # Custom file
./vod batch download --continue-on-error   # Don't stop on failure
```

### `vod batch transcribe [file]`
Batch transcribe videos from a URL file.
```bash
./vod batch transcribe                              # Process urls.txt
./vod batch transcribe my-urls.txt                  # Custom file
./vod batch transcribe --quality 720p               # Higher quality Twitch
./vod batch transcribe --download-youtube           # Force YouTube download
./vod batch transcribe --continue-on-error          # Don't stop on failure
```

### `vod split <file> [hours]`
Split video files into time-based chunks.
```bash
./vod split video.mp4              # 5-hour chunks (default)
./vod split video.mp4 3            # 3-hour chunks
```

### `vod twitchdownloader <url>` (alias: `vod td`)
Download Twitch VOD with chat overlay using TwitchDownloaderCLI.
```bash
./vod twitchdownloader https://www.twitch.tv/videos/2588036186
./vod twitchdownloader --quality 720p60 2588036186
./vod td -w 500 -h 1080 2588036186
```

### `vod web`
Start the web interface for queue management.
```bash
./vod web
```
Opens a web UI at http://localhost:8080 with:
- View and manage download/transcription queues
- Add/remove URLs with optional prefixes
- System status (NAS mount, GPU availability)
- Real-time queue counts

## URL File Format

Both `urls.txt` (transcription) and `urls-vods` (downloads) use the same format:

```bash
# Comments start with #
https://www.twitch.tv/videos/2588036186
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://youtu.be/jNQXAC9IVRw my-custom-prefix

# Blank lines are ignored
```

Optional prefixes are appended to filenames (useful for organization).

## NAS Support

If `/nas` is mounted, videos are automatically saved to `/nas/vods/{channel}/`. Otherwise, they go to the local `videos/` directory.

To unmount the NAS:
```bash
./vod unmount-nas
```

## Project Structure

```
.
├── vod                            # Main CLI entrypoint
├── scripts/                       # Command implementations
│   ├── download.sh                # vod download
│   ├── unmount-nas.sh             # vod unmount-nas
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
├── transcripts/                   # Output transcripts (txt)
│   ├── {channel}/                 # Twitch transcripts by channel
│   └── youtube/                   # YouTube transcripts
├── vods/                          # Downloaded videos/audio
│   ├── {channel}/                 # Twitch VODs by channel
│   └── youtube/                   # YouTube downloads
├── videos/                        # TwitchDownloader outputs
├── summaries/                     # AI-generated summaries
└── logs/                          # Execution logs
```

## Dependencies

### Python
```bash
pip install -r requirements.txt
```
Core: `faster-whisper`, `twitch-dl`, `yt-dlp`

### System
- `ffmpeg` - Audio/video processing
- `ffprobe` - Duration detection
- `TwitchDownloaderCLI` (optional) - Chat overlay rendering

## YouTube Premium Authentication

To access higher quality streams, age-restricted videos, or members-only content with YouTube Premium:

### Export cookies from your browser

Install the **"Get cookies.txt LOCALLY"** browser extension:
- [Chrome](https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)
- [Firefox](https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/)

Then:
1. Go to https://www.youtube.com and make sure you're logged in
2. Click the extension icon → "Export" or "Current Site"
3. Save the contents to `cookies.txt` in the project root

The scripts will automatically detect and use `cookies.txt` if it exists.

### Security Notes
- `cookies.txt` is in `.gitignore` - never commit it
- Treat this file like a password
- Cookies expire periodically - re-export when authentication fails

### GPU Acceleration
- CUDA auto-detection for faster-whisper
- RTX A2000 (8GB VRAM) runs `large-v3` model
- Falls back to CPU if CUDA unavailable

## Features

- ✅ **Unified CLI** - Single `vod` command with intuitive subcommands
- ✅ **Batch processing** - Process multiple URLs from file
- ✅ **Auto-detection** - Recognizes Twitch and YouTube URLs
- ✅ **Smart fallback** - YouTube captions first, auto-downloads if unavailable
- ✅ **Chapter splitting** - Automatic chapter extraction with sanitized filenames
- ✅ **Long video handling** - Auto-split videos >6 hours into 5-hour chunks
- ✅ **NAS support** - Automatic path routing based on mount detection
- ✅ **Progress tracking** - Move completed URLs to processed file
- ✅ **CUDA acceleration** - GPU-powered transcription with Whisper
- ✅ **Chat overlay** - TwitchDownloader integration for chat rendering
- ✅ **Web interface** - Browser-based queue management at localhost:8080

## Help

```bash
./vod --help                  # Show all commands
./vod download --help         # Command-specific help
./vod batch transcribe --help # Subcommand help
```

See [USAGE.md](USAGE.md) for detailed usage instructions
