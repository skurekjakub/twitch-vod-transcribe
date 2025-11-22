# Twitch & YouTube VOD Transcriber - AI Coding Agent Instructions

## Project Overview
Modular bash/Python pipeline that downloads and transcribes Twitch VODs and YouTube videos using OpenAI's Whisper model (via `faster-whisper`). Features reusable library components for audio extraction and transcription, plus batch processing for daily workflows.

## Architecture & Data Flow

### Batch Processing Workflow (via `batch-transcribe.sh`)
**Primary entry point for daily use** - processes 3-5 videos from a URL list:
1. **Read URLs** → Parses `urls.txt` (or specified file) line-by-line
2. **Auto-detect** → Identifies Twitch vs YouTube URLs via regex
3. **Route** → Calls appropriate script (`vod-transcribe.sh` or `youtube-transcript-ytdlp.sh`)
4. **Smart Retry** → For YouTube: tries caption fetch first, auto-retries with download if no captions
5. **Progress Tracking** → Logs all operations to `logs/batch-{timestamp}.log`

### Twitch Workflow (via `vod-transcribe.sh`)
1. **Download** → Uses `twitch-dl` to fetch VOD at specified quality (default 480p)
2. **Extract Audio** → Calls `lib/extract-audio.sh` (ffmpeg) to extract AAC audio from MP4
3. **Transcribe** → Calls `lib/transcribe-audio.sh` (faster-whisper) to generate plain text transcript
4. **Organize** → Files stored in channel-specific directories

### YouTube Workflow (via `youtube-transcript-ytdlp.sh`)
1. **Fetch Captions** → Uses `yt-dlp` to download existing YouTube captions (if available)
2. **Convert to Text** → Strips timestamps/formatting from SRT to plain text
3. **Smart Fallback** → If no captions exist:
   - **Automatic** (in batch mode): Downloads m4a → Calls `lib/transcribe-audio.sh`
   - **Manual** (single video): Requires `--download` or `--download-video` flag
4. **Fallback Modes**:
   - Audio-only (`--download`): Downloads m4a → Calls `lib/transcribe-audio.sh`
   - Video (`--download-video`): Downloads mp4 → Calls `lib/extract-audio.sh` → Calls `lib/transcribe-audio.sh`

### File Organization Pattern
```
vods/
  {channel}/                    # Twitch VODs organized by channel
    {channel}-{YYYY-MM-DD}-{title-prefix}.mp4
    {channel}-{YYYY-MM-DD}-{title-prefix}.aac
  youtube/                      # YouTube downloads
    {channel}-{YYYY-MM-DD}-{title-prefix}.m4a  (--download)
    {channel}-{YYYY-MM-DD}-{title-prefix}.mp4  (--download-video)
    {channel}-{YYYY-MM-DD}-{title-prefix}.aac  (--download-video)
transcripts/
  {channel}/                    # Twitch transcripts by channel
    {channel}-{YYYY-MM-DD}-{title-prefix}-en.txt
  youtube/                      # YouTube transcripts
    {channel}-{YYYY-MM-DD}-{title-prefix}-{lang}.txt
summaries/
  {channel}-{YYYY-MM-DD}-{title-prefix}-SUMMARY.md
logs/
  run-{timestamp}.log
  transcribe-{timestamp}.log
  extract-{timestamp}.log
```

**Naming convention**: `{channel}-{date}-{first-20-chars-of-title}` - extracted from download tool output formats

## Key Commands

### Batch Processing (Recommended for Daily Use)
```bash
# Process all URLs in urls.txt (default file)
./batch-transcribe.sh

# Use custom URL file
./batch-transcribe.sh my-urls.txt

# Custom quality for Twitch + force YouTube downloads
./batch-transcribe.sh --quality 720p --download-youtube

# Continue processing even if one fails
./batch-transcribe.sh --continue-on-error

# Full options
./batch-transcribe.sh --quality 720p --download-video-youtube --youtube-lang es --continue-on-error
```

**Batch Options:**
- `--quality QUALITY` - Twitch video quality (default: 480p)
- `--download-youtube` - Force audio download for YouTube (skips caption check)
- `--download-video-youtube` - Force video download for YouTube
- `--youtube-lang LANG` - Caption language preference (default: en)
- `--continue-on-error` - Don't stop on individual URL failures

**URL File Format** (`urls.txt`):
```
# Comments start with #
https://www.twitch.tv/videos/2588036186
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://youtu.be/jNQXAC9IVRw

# Blank lines ignored
```

### Entry Point Scripts (Single Video)
```bash
# Twitch VOD transcription
./vod-transcribe.sh https://www.twitch.tv/videos/2588036186  # Full pipeline
./vod-transcribe.sh --quality 720p <url>                     # Custom quality
./vod-transcribe.sh --download-only <url>                    # Skip transcription

# YouTube transcription
./youtube-transcript-ytdlp.sh <url>                          # Fetch captions only
./youtube-transcript-ytdlp.sh --download <url>               # Audio download + transcribe
./youtube-transcript-ytdlp.sh --download-video <url>         # Video download + extract + transcribe
./youtube-transcript-ytdlp.sh --lang es <url>                # Specify caption language
```

### Library Scripts (Reusable Components)
```bash
lib/extract-audio.sh <video.mp4> <output.aac>     # Extract audio from video
lib/transcribe-audio.sh <audio.m4a> <output.txt>  # Transcribe audio to text
```

### Standalone Tools
```bash
python download_vod.py <url>                      # Download Twitch VOD only
```

### TwitchDownloader (Advanced Video + Chat Overlay)
```bash
# Download VOD with chat overlay at 1080p60 (uses TwitchDownloader CLI)
./download-video-twitchdownloader.sh https://www.twitch.tv/videos/2588036186
./download-video-twitchdownloader.sh 2588036186  # VOD ID also works

# Custom quality and chat dimensions
./download-video-twitchdownloader.sh --quality 720p60 -w 500 -h 720 <url>

# Custom output directory
./download-video-twitchdownloader.sh --output-dir custom_videos <url>
```

**TwitchDownloader Options:**
- `-q, --quality QUALITY` - Video quality (default: 1080p60, NOT 4K)
  - Examples: `1080p60`, `1080p`, `720p60`, `720p`, `480p`
  - Downloads highest available if exact quality not found
- `-w, --chat-width WIDTH` - Chat overlay width in pixels (default: 420)
- `-h, --chat-height HEIGHT` - Chat overlay height in pixels (default: 1080)
- `-o, --output-dir DIR` - Output directory (default: videos)

**TwitchDownloader Workflow:**
1. **Video Download** → Uses TwitchDownloaderCLI to fetch VOD at specified quality (1080p60 by default)
2. **Chat Download** → Downloads chat with embedded emotes (BTTV, FFZ, 7TV)
3. **Chat Render** → Renders chat at 60fps with transparent background (#00000000) in MOV/ProRes format
4. **Composite** → Uses ffmpeg to overlay chat onto video at top-right corner (10px padding)

**Output Files:**
- `{VOD_ID}.mp4` - Original video
- `{VOD_ID}_chat.json` - Chat data with embedded emotes
- `{VOD_ID}_chat.mov` - Transparent chat overlay (ProRes codec with alpha channel)
- `{VOD_ID}_with_chat.mp4` - Final video with chat overlay composited

**Key Features:**
- 60fps chat rendering for smooth animations
- Transparent background (full alpha channel support) for overlay compositing
- Chat positioned at top-right with customizable dimensions
- Outline rendering for better text readability
- Embedded emotes for offline rendering (BTTV, FFZ, 7TV)
- All operations logged to `logs/twitchdownloader-{timestamp}.log`

## Project Structure
```
.
├── batch-transcribe.sh                  # Batch processor (main entry point)
├── vod-transcribe.sh                    # Twitch VOD entry point
├── youtube-transcript-ytdlp.sh          # YouTube entry point
├── download_vod.py                      # Standalone Twitch downloader (twitch-dl)
├── download-video-twitchdownloader.sh   # Advanced Twitch downloader with chat overlay
├── urls.txt                             # Default URL list for batch processing
├── urls-batch.example.txt               # Example URL file format
├── lib/                                 # Reusable helper scripts
│   ├── extract-audio.sh                 # Audio extraction (ffmpeg wrapper)
│   └── transcribe-audio.sh              # Transcription (Whisper wrapper)
├── transcripts/                         # Plain text transcripts
├── vods/                                # Downloaded videos/audio
├── videos/                              # TwitchDownloader outputs (with chat overlays)
├── summaries/                           # AI-generated summaries
└── logs/                                # Execution logs
```

## Environment & Dependencies

### Python Environment
- Auto-activates `venv/` if present, falls back to system Python
- Core dependencies: `faster-whisper`, `twitch-dl`
- YouTube support: `yt-dlp` (install separately: `pip install yt-dlp`)

### GPU Acceleration
- **CUDA auto-detection**: `lib/transcribe-audio.sh` uses `device="cuda"` with `float16` compute type
- **RTX A2000 (8GB VRAM)**: Runs `large-v3` model successfully
- Whisper models cached in `~/.cache/huggingface/hub/` (~3GB download on first run)
- Performance: ~30-60 min for 4-hour VOD with CUDA, ~2-4 hours on CPU

### Model Configuration
Located in `lib/transcribe-audio.sh` Python block:
```python
model = WhisperModel("large-v3", device="cuda", compute_type="float16")
```
Change to `"medium"` or `"small"` for lower VRAM GPUs.

## Critical Implementation Details

### Error Handling & Cleanup
- Uses bash `trap` to clean up partial files on failure
- Separate traps for download, audio extraction, and transcription phases
- All operations logged to `logs/{operation}-{timestamp}.log`

### File Discovery Pattern (Twitch)
Downloads create files matching `*_${VOD_ID}_*.mp4`. Script uses:
```bash
downloaded_file=$(ls -t *"_${VOD_ID}_"*.mp4 2>/dev/null | head -n 1)
```
Then parses with regex: `^([0-9]{4}-[0-9]{2}-[0-9]{2})_${VOD_ID}_([^_]+)_(.+)\.mp4$`

### File Discovery Pattern (YouTube)
yt-dlp creates files like `{channel}-{date}-{title}.{lang}.srt`. Script finds with:
```bash
subtitle_file=$(ls "${transcript_dir}/${base_name}."*".srt" 2>/dev/null | head -n 1)
```

### Whisper Transcription Settings
- `vad_filter=True` with `min_silence_duration_ms=500` filters silence
- `beam_size=5` for quality vs speed balance
- Plain text output: only text content with double-newline separators (no timestamps)

### YouTube Caption Processing
- SRT format stripped to plain text using grep/sed pipeline:
  - Remove sequence numbers (`^[0-9]*$`)
  - Remove timestamps (`^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]`)
  - Remove HTML tags (`s/<[^>]*>//g`)
  - Remove blank lines

## Development Conventions

### Logging Pattern
All operations use: `echo "$ID - $timestamp - <message>" | tee -a "${logs_dir}/{script}-${timestamp}.log"`

### URL Validation
- Twitch: `^https://www\.twitch\.tv/videos/[0-9]+$`
- YouTube: Accepts `youtube.com/watch?v=` and `youtu.be/` formats
- Batch script auto-detects type and routes accordingly

### Batch Processing Logic
**YouTube Smart Fallback** (in `batch-transcribe.sh`):
1. Try caption fetch first (fast, no download)
2. If caption fetch fails AND `--download-youtube` was NOT specified:
   - Log retry message
   - Automatically call `youtube-transcript-ytdlp.sh --download` (audio transcription)
3. If caption fetch succeeds: use captions
4. If both fail: mark as failed (continue or exit based on `--continue-on-error`)

**URL Processing**:
- Reads `urls.txt` by default (override with positional argument)
- Skips blank lines and lines starting with `#`
- Trims whitespace from URLs
- Processes sequentially (not parallel) to avoid resource contention
- Logs: `[X/Y] Processing: <url>` format for progress tracking

### Error Handling Patterns
**Batch Script**:
- Two modes: fail-fast (default) or continue-on-error
- Tracks counters: `successful`, `failed`, `skipped`
- Comprehensive summary at end
- Exit code 1 if any failures (unless `--continue-on-error`)

**Individual Scripts**:
- Use bash `trap` to clean up partial files on failure
- Separate traps for download, audio extraction, and transcription phases
- All operations logged to `logs/{operation}-{timestamp}.log`

## Output Artifacts
- **Transcripts**: Plain text files (`.txt`) with text-only content, double-newline separated
- **Summaries**: AI-generated markdown files in `summaries/` (see `.github/summary-generation-prompt.md`)
- **Logs**: Timestamped logs for each script execution
- **Videos/Audio**: Organized by source (channel name or "youtube") in `vods/`

## Summary Generation Workflow
Use `.github/summary-generation-prompt.md` as a comprehensive template for generating stream summaries:
1. Open transcript TXT file from `transcripts/{channel}/`
2. Reference the prompt template in Copilot Chat
3. Generate structured markdown summary with trading positions, market analysis, and key takeaways
4. Save to `summaries/` with naming: `{channel}-{YYYY-MM-DD}-{title-prefix}-SUMMARY.md`

## Common Patterns

### Daily Workflow
1. Add URLs to `urls.txt` (one per line, mix Twitch/YouTube)
2. Run `./batch-transcribe.sh` (or with `--continue-on-error` for resilience)
3. Check `logs/batch-{timestamp}.log` for results
4. Find transcripts in `transcripts/{channel}/` or `transcripts/youtube/`
5. Generate summaries using `.github/summary-generation-prompt.md`

### Transcript Format
All transcripts are plain text (`.txt`) files with:
- No timestamps or sequence numbers
- Text separated by double newlines
- HTML tags stripped
- Consistent across Twitch and YouTube sources

### Audio Extraction
Always uses `lib/extract-audio.sh` which:
- Copies audio codec without re-encoding (`-acodec copy`)
- Preserves original audio quality
- Outputs AAC format for Twitch, preserves format for YouTube

### Transcription
Always uses `lib/transcribe-audio.sh` which:
- Loads Whisper model once per execution
- Uses CUDA if available
- Outputs plain text with consistent formatting
- Logs progress every 100 segments
