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
./vod list-playlist PLxxxxxxx -o --prefix "name"  # URLs with prefix for batch download
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

## Environment & Dependencies

### Python Environment
- Auto-activates `venv/` if present, falls back to system Python
- Core dependencies: `faster-whisper`, `twitch-dl`, `yt-dlp`
- Web interface: `fastapi`, `uvicorn`

### System Dependencies
- `ffmpeg` / `ffprobe` - Audio/video processing
- `TwitchDownloaderCLI` (optional) - Chat overlay rendering

## Critical Implementation Details

### Script Path Resolution
All scripts use this pattern to find the project root:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"
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

## Common Patterns

## Testing Requirements

**CRITICAL: Always run tests after modifying any shell script logic.**

### Todo List for Large-Scale Changes
**ALWAYS create a todo list when making multi-step changes to track:**
1. Implementation of the core feature/fix
2. Update help text if options/usage changed
3. Add or update tests for new/modified functionality
4. Update copilot-instructions.md if workflows/commands changed
5. Run the full test suite before considering work complete
6. Verify shellcheck passes

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

### Updating Tests for Modified Functionality
**CRITICAL: When modifying existing functionality, always update corresponding tests:**
1. Add tests for new options/flags before or alongside implementation
2. Update help text tests if usage/options changed
3. Verify existing tests still pass with the changes
4. Add edge case tests for new behavior
5. Run the full test suite: `./test/run_tests.sh`
