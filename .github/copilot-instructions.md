# Twitch & YouTube VOD Transcriber - AI Coding Agent Instructions

## Project Overview
Modular bash/Python pipeline that downloads and transcribes Twitch VODs and YouTube videos using OpenAI's Whisper model (via `faster-whisper`). Features reusable library components for audio extraction and transcription.

## Architecture & Data Flow

### Twitch Workflow (via `vod-transcribe.sh`)
1. **Download** → Uses `twitch-dl` to fetch VOD at specified quality (default 480p)
2. **Extract Audio** → Calls `lib/extract-audio.sh` (ffmpeg) to extract AAC audio from MP4
3. **Transcribe** → Calls `lib/transcribe-audio.sh` (faster-whisper) to generate plain text transcript
4. **Organize** → Files stored in channel-specific directories

### YouTube Workflow (via `youtube-transcript-ytdlp.sh`)
1. **Fetch Captions** → Uses `yt-dlp` to download existing YouTube captions (if available)
2. **Convert to Text** → Strips timestamps/formatting from SRT to plain text
3. **Fallback Download** → If no captions exist and `--download`/`--download-video` specified:
   - Audio-only: Downloads m4a → Calls `lib/transcribe-audio.sh`
   - Video: Downloads mp4 → Calls `lib/extract-audio.sh` → Calls `lib/transcribe-audio.sh`

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

### Entry Point Scripts
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

## Project Structure
```
.
├── vod-transcribe.sh              # Twitch VOD entry point
├── youtube-transcript-ytdlp.sh    # YouTube entry point
├── download_vod.py                # Standalone Twitch downloader
├── lib/                           # Reusable helper scripts
│   ├── extract-audio.sh           # Audio extraction (ffmpeg wrapper)
│   └── transcribe-audio.sh        # Transcription (Whisper wrapper)
├── transcripts/                   # Plain text transcripts
├── vods/                          # Downloaded videos/audio
├── summaries/                     # AI-generated summaries
└── logs/                          # Execution logs
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

### Quality Options
- Twitch: `160p`, `360p`, `480p`, `720p`, `720p60`, `1080p`, `1080p60`, `source`
- YouTube: Handled by yt-dlp (`bestaudio`, `worst`, etc.)

## Modular Design Philosophy

### Library Scripts (`lib/`)
- **Purpose**: Reusable, single-responsibility components
- **Interface**: Take file paths as arguments, output to specified locations
- **Independence**: Can be called from any script or used standalone
- **Logging**: Each script logs to its own timestamped log file

### Entry Point Scripts (Top-level)
- **Purpose**: End-to-end workflows for specific use cases
- **Responsibilities**: Download management, file organization, workflow orchestration
- **Delegation**: Call library scripts for audio extraction and transcription
- **User-facing**: Designed for direct command-line usage

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
