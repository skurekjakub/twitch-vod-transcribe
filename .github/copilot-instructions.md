# Twitch & YouTube VOD Transcriber - AI Coding Agent Instructions

## Project Overview
Unified CLI tool (`vod`) for downloading and transcribing Twitch VODs and YouTube videos using OpenAI's Whisper model (via `faster-whisper`). Features reusable library components for audio extraction and transcription, plus batch processing for daily workflows.

## Architecture & Data Flow

### CLI Structure
The project uses a single entrypoint `./vod` with subcommands:
- `vod download` - Download video with chapter splitting
- `vod transcribe` - Download Twitch VOD + transcribe
- `vod youtube` - YouTube caption/transcribe
- `vod list` - List Twitch channel VODs
- `vod list-youtube` (aliases: `list-yt`, `lyt`) - List YouTube channel videos
- `vod list-playlist` (alias: `lpl`) - List YouTube playlist videos
- `vod batch download` - Batch download from file
- `vod batch transcribe` - Batch transcribe from file
- `vod split` - Split video into chunks
- `vod twitchdownloader` (alias: `vod td`) - Download with chat overlay
- `vod web` - Start web interface for queue management

### Batch Transcribe Workflow (`vod batch transcribe`)
**Primary entry point for daily use** - processes videos from a URL list:
1. **Read URLs** → Parses `urls.txt` (or specified file) line-by-line
2. **Auto-detect** → Identifies Twitch vs YouTube URLs via regex
3. **Route** → Calls appropriate script (`scripts/transcribe.sh` or `scripts/youtube.sh`)
4. **Smart Retry** → For YouTube: tries caption fetch first, auto-retries with download if no captions
5. **Progress Tracking** → Logs all operations to `logs/batch-{timestamp}.log`

### Batch Download Workflow (`vod batch download`)
**Archival entry point** - downloads videos without transcription:
1. **Read URLs** → Parses `urls-vods` (or specified file)
2. **Parse Prefixes** → Extracts optional filename prefixes (e.g., `url prefix`)
3. **NAS Detection** → Checks if `/nas` is mounted
4. **Download** → Calls `scripts/download.sh` to download via `yt-dlp`
5. **Track Progress** → Moves completed URLs to `{file}-processed`
6. **Save** → Saves to `/nas/vods/{channel}/` (if NAS) or `videos/` (local)
7. **Error Handling** → Continues on error by default, detects incomplete `.part` files

### Twitch Workflow (`vod transcribe`)
1. **Download** → Uses `twitch-dl` to fetch VOD at specified quality (default 480p)
2. **Extract Audio** → Calls `lib/extract-audio.sh` (ffmpeg) to extract AAC audio from MP4
3. **Transcribe** → Calls `lib/transcribe-audio.sh` (faster-whisper) to generate plain text transcript
4. **Organize** → Files stored in channel-specific directories

### YouTube Workflow (`vod youtube`)
1. **Fetch Captions** → Uses `yt-dlp` to download existing YouTube captions (if available)
2. **Convert to Text** → Strips timestamps/formatting from SRT to plain text
3. **Smart Fallback** → If no captions exist and `--download` specified:
   - Downloads audio → Calls `lib/transcribe-audio.sh`
4. **Fallback Modes**:
   - Audio-only (`--download`): Downloads m4a → Calls `lib/transcribe-audio.sh`

### Download Workflow (`vod download`)
1. **Fetch Metadata** → Gets video info via yt-dlp
2. **Download** → Downloads with `--split-chapters` for automatic chapter splitting
3. **Sanitize** → Uses `%(section_title)#S` for filesystem-safe chapter names
4. **Auto-Split** → Splits videos >6 hours into 5-hour chunks
5. **NAS Routing** → Saves to `/nas/vods/{channel}/` if mounted, else `videos/`

### File Organization Pattern
```
vods/
  {channel}/                    # Twitch VODs organized by channel
    {channel}-{YYYY-MM-DD}-{title-prefix}.mp4
    {channel}-{YYYY-MM-DD}-{title-prefix}.aac
  youtube/                      # YouTube downloads
    {channel}-{YYYY-MM-DD}-{title-prefix}.m4a
/nas/vods/                      # NAS Storage (if mounted)
  {channel}/
    {date}-{title}-{##}-{chapter}.mp4   # Chapter-split files
videos/                         # Local fallback / TwitchDownloader outputs
transcripts/
  {channel}/                    # Twitch transcripts by channel
    {channel}-{YYYY-MM-DD}-{title-prefix}-en.txt
  youtube/                      # YouTube transcripts
    {channel}-{YYYY-MM-DD}-{title-prefix}-{lang}.txt
summaries/
  {channel}-{YYYY-MM-DD}-{title-prefix}-SUMMARY.md
logs/
  run-{timestamp}.log
  batch-{timestamp}.log
  download-{timestamp}.log
```

## Key Commands

### Main CLI
```bash
./vod --help                    # Show all commands
./vod <command> --help          # Command-specific help
```

### Download Videos
```bash
# Download with chapter splitting
./vod download https://www.youtube.com/watch?v=VIDEO_ID
./vod download https://www.twitch.tv/videos/12345 my-prefix

# Features: chapter splitting, 5-hour auto-split, NAS detection, H.264/AAC codecs
```

### Transcribe Twitch VODs
```bash
./vod transcribe https://www.twitch.tv/videos/2588036186
./vod transcribe --quality 720p https://www.twitch.tv/videos/2588036186
./vod transcribe --download-only https://www.twitch.tv/videos/2588036186
```

### YouTube Transcription
```bash
./vod youtube https://www.youtube.com/watch?v=VIDEO_ID           # Captions only
./vod youtube --download https://www.youtube.com/watch?v=VIDEO_ID # Audio + Whisper
./vod youtube --lang es https://www.youtube.com/watch?v=VIDEO_ID  # Spanish captions
```

### List Twitch VODs
```bash
./vod list forsen                          # Human-readable list
./vod list forsen --urls-only              # Just URLs (for piping)
./vod list forsen --limit 10               # Last 10 VODs
./vod list forsen --chapters               # Include chapter info
./vod list forsen --urls-only >> urls-vods # Add to download queue
```

### List YouTube Videos
```bash
./vod list-youtube @MrBeast                # List channel videos
./vod list-youtube @MrBeast --urls-only    # Just URLs
./vod list-youtube @MrBeast --limit 20     # Last 20 videos
./vod lyt @MrBeast -o                      # Short alias
```

### List YouTube Playlist
```bash
./vod list-playlist PLxxxxxxx              # List playlist videos
./vod list-playlist PLxxxxxxx --urls-only  # Just URLs
./vod lpl PLxxxxxxx -o                     # Short alias
```

### Batch Processing
```bash
# Batch transcription (default: urls.txt)
./vod batch transcribe
./vod batch transcribe my-urls.txt
./vod batch transcribe --quality 720p --download-youtube
./vod batch transcribe --continue-on-error

# Batch download (default: urls-vods, continues on error by default)
./vod batch download
./vod batch download my-list.txt
```

### Video Splitting
```bash
./vod split video.mp4              # 5-hour chunks (default)
./vod split video.mp4 3            # 3-hour chunks
```

### TwitchDownloader (Chat Overlay)
```bash
./vod twitchdownloader https://www.twitch.tv/videos/2588036186
./vod twitchdownloader --quality 720p60 2588036186
./vod td -w 500 -h 1080 2588036186    # Short alias
```

### Web Interface
```bash
./vod web                              # Start web UI at http://localhost:8080
```
Features:
- View/manage download queue (`urls-vods`) and transcribe queue (`urls.txt`)
- Add/remove URLs with optional prefixes
- System status (NAS mount, GPU availability)
- Real-time queue counts

### Library Scripts (Direct Use)
```bash
./lib/extract-audio.sh <video.mp4> <output.aac>     # Extract audio
./lib/transcribe-audio.sh <audio.m4a> <output.txt>  # Transcribe audio
```

## URL File Format
Both `urls.txt` (transcription) and `urls-vods` (downloads) use the same format:
```bash
# Comments start with #
https://www.twitch.tv/videos/2588036186
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://youtu.be/jNQXAC9IVRw my-prefix  # Optional filename prefix

# Blank lines ignored
```

## Project Structure
```
.
├── vod                            # Main CLI entrypoint
├── scripts/                       # Command implementations
│   ├── download.sh                # vod download
│   ├── transcribe.sh              # vod transcribe
│   ├── youtube.sh                 # vod youtube
│   ├── list.sh                    # vod list
│   ├── list-youtube.sh            # vod list-youtube
│   ├── list-playlist.sh           # vod list-playlist
│   ├── batch-download.sh          # vod batch download
│   ├── batch-transcribe.sh        # vod batch transcribe
│   ├── split.sh                   # vod split
│   └── twitchdownloader.sh        # vod twitchdownloader
├── web/                           # Web interface
│   └── app.py                     # FastAPI app (vod web)
├── lib/                           # Shared helper scripts
│   ├── extract-audio.sh           # Audio extraction (ffmpeg)
│   └── transcribe-audio.sh        # Transcription (Whisper)
├── python/                        # Python utilities
│   ├── download_vod.py            # Standalone Twitch downloader
│   └── maya_tts.py                # TTS utility
├── urls.txt                       # Default transcription URL list
├── urls-vods                      # Default download URL list
├── transcripts/                   # Output transcripts
├── vods/                          # Downloaded videos/audio
├── videos/                        # TwitchDownloader outputs
├── summaries/                     # AI-generated summaries
└── logs/                          # Execution logs
```

## Environment & Dependencies

### Python Environment
- Auto-activates `venv/` if present, falls back to system Python
- Core dependencies: `faster-whisper`, `twitch-dl`, `yt-dlp`
- Web interface: `fastapi`, `uvicorn`

### System Dependencies
- `ffmpeg` / `ffprobe` - Audio/video processing
- `TwitchDownloaderCLI` (optional) - Chat overlay rendering

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

### Script Path Resolution
All scripts use this pattern to find the project root:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"
```

### Error Handling & Cleanup
- Uses bash `trap` to clean up partial files on failure
- Separate traps for download, audio extraction, and transcription phases
- All operations logged to `logs/{operation}-{timestamp}.log`

### Chapter Splitting (vod download)
- Uses `--split-chapters` with yt-dlp
- Output template: `%(section_number)02d-%(section_title)#S.%(ext)s`
- `#S` flag sanitizes filenames (restricted character set)
- Removes the "full" video file, keeps only chapters

### Auto-Split for Long Videos
Videos >6 hours are split into 5-hour chunks:
```bash
ffmpeg -i "$video_file" -c copy -map 0 -segment_time 18000 -f segment -reset_timestamps 1 "${file_base}-part%02d.mp4"
```

### URL Processing Tracking
Batch download tracks progress by moving completed URLs:
```bash
mark_processed() {
  echo "# Processed: $(date)" >> "$PROCESSED_FILE"
  echo "$line" >> "$PROCESSED_FILE"
  grep -vFx "$line" "$URL_FILE" > "${URL_FILE}.tmp"
  mv "${URL_FILE}.tmp" "$URL_FILE"
}
```

### NAS Detection
```bash
if grep -qs " /nas " /proc/mounts; then
  video_dir="/nas/vods/${channel_clean}"
else
  video_dir="videos"
fi
```

## Development Conventions

### Logging Pattern
```bash
log() {
  echo "$ID - $(date +%Y.%m.%d-%H:%M:%S) - $1" | tee -a "$log_file"
}
```

### URL Validation
- Twitch VOD: `^https://www\.twitch\.tv/videos/[0-9]+$`
- YouTube: `youtube.com/watch?v=` and `youtu.be/` formats
- General: `^https?://` for downloads

### Help Text Pattern
All scripts support `-h` and `--help`:
```bash
case $1 in
  -h|--help)
    cat << 'EOF'
Command Name

Usage: vod command [options] <args>

Description...

Options:
  --option    Description
  -h, --help  Show this help

Examples:
  vod command example
EOF
    exit 0
    ;;
esac
```

## Common Patterns

### Daily Workflow
1. Add URLs to `urls.txt` (one per line, mix Twitch/YouTube)
2. Run `./vod batch transcribe` (or with `--continue-on-error`)
3. Check `logs/batch-{timestamp}.log` for results
4. Find transcripts in `transcripts/{channel}/` or `transcripts/youtube/`
5. Generate summaries using `.github/summary-generation-prompt.md`

### Archival Workflow
1. List VODs: `./vod list channelname --urls-only >> urls-vods`
2. Run `./vod batch download`
3. Completed URLs move to `urls-vods-processed`
4. Videos saved to `/nas/vods/{channel}/` with chapters

### Transcript Format
All transcripts are plain text (`.txt`) files with:
- No timestamps or sequence numbers
- Text separated by double newlines
- HTML tags stripped
- Consistent across Twitch and YouTube sources

### Audio Extraction
Uses `lib/extract-audio.sh`:
- Copies audio codec without re-encoding (`-acodec copy`)
- Preserves original audio quality
- Outputs AAC format

### Transcription
Uses `lib/transcribe-audio.sh`:
- Loads Whisper model once per execution
- Uses CUDA if available
- `vad_filter=True` with `min_silence_duration_ms=500`
- `beam_size=5` for quality vs speed
- Outputs plain text with consistent formatting

## Testing Requirements

**CRITICAL: Always run tests after modifying any shell script logic.**

### Test Infrastructure
- Framework: `bats-core` (Bash Automated Testing System)
- Test location: `test/*.bats`
- Helper libraries: `bats-support`, `bats-assert`, `bats-file`

### Running Tests
```bash
# Run all tests
./test/run_tests.sh

# Run specific test file
./test/run_tests.sh vod.bats

# Run with verbose output
./test/run_tests.sh -v

# Run shellcheck linting
./test/bats-core/bin/bats test/shellcheck.bats
```

### When to Run Tests
**Run the full test suite after ANY of these changes:**
- Modifying `vod` entrypoint
- Editing any script in `scripts/` directory
- Editing any script in `lib/` directory
- Adding new command-line options
- Changing URL parsing or validation logic
- Modifying file path handling
- Updating error messages or help text

### Test Coverage
Tests cover:
- Help/usage text for all commands
- Argument validation and parsing
- URL validation (Twitch, YouTube formats)
- Command routing and aliases
- Error handling paths
- ShellCheck linting for all scripts

### Adding New Tests
When adding new functionality:
1. Add tests to the appropriate `test/*.bats` file
2. Use existing mocking patterns from `test/test_helper/common-setup.bash`
3. Run `./test/run_tests.sh` to verify all tests pass
4. Ensure `shellcheck.bats` still passes
