# Twitch VOD Transcriber - AI Coding Agent Instructions

## Project Overview
Python/Bash pipeline that downloads Twitch VODs and transcribes them using OpenAI's Whisper model (via `faster-whisper`). Outputs organized SRT subtitle files by channel.

## Architecture & Data Flow

### Primary Workflow (via `vod-transcribe.sh`)
1. **Download** → Uses `twitch-dl` to fetch VOD at specified quality (default 480p)
2. **Extract** → `ffmpeg` extracts AAC audio from MP4
3. **Transcribe** → `faster-whisper` with `large-v3` model generates English SRT subtitles
4. **Organize** → Files stored in channel-specific directories

### File Organization Pattern
```
vods/
  {channel}/
    {channel}-{YYYY-MM-DD}-{title-prefix}.mp4
    {channel}-{YYYY-MM-DD}-{title-prefix}.aac
transcripts/
  {channel}/
    {channel}-{YYYY-MM-DD}-{title-prefix}-en.srt
summaries/
  {channel}-{YYYY-MM-DD}-{title-prefix}-SUMMARY.md
logs/
  run-{timestamp}.log
```

**Naming convention**: `{channel}-{date}-{first-20-chars-of-title}` - extracted from twitch-dl's output format `YYYY-MM-DD_VODID_channel_title.mp4`

## Key Commands

### Main Script (One-Step Process)
```bash
./vod-transcribe.sh https://www.twitch.tv/videos/2588036186  # Full pipeline
./vod-transcribe.sh --quality 720p <url>                     # Custom quality
./vod-transcribe.sh --download-only <url>                    # Skip transcription
```

### Standalone Components
```bash
python download_vod.py <url>           # Download only (to current dir)
```

## Environment & Dependencies

### Python Environment
- Auto-activates `venv/` if present, falls back to system Python
- Main dependencies: `faster-whisper`, `twitch-dl`

### GPU Acceleration
- **CUDA auto-detection**: Script uses `device="cuda"` with `float16` compute type
- **RTX A2000 (8GB VRAM)**: Runs `large-v3` model successfully
- Whisper models cached in `~/.cache/huggingface/hub/` (~3GB download on first run)
- Performance: ~30-60 min for 4-hour VOD with CUDA, ~2-4 hours on CPU

### Model Configuration
Located in `vod-transcribe.sh` Python inline block:
```python
model = WhisperModel("large-v3", device="cuda", compute_type="float16")
```
Change to `"medium"` or `"small"` for lower VRAM GPUs.

## Critical Implementation Details

### Error Handling & Cleanup
- Uses bash `trap` to clean up partial files on failure
- Separate traps for download, audio extraction, and transcription phases
- All operations logged to `logs/run-{timestamp}.log`

### File Discovery Pattern
Downloads create files matching `*_${VOD_ID}_*.mp4`. Script uses:
```bash
downloaded_file=$(ls -t *"_${VOD_ID}_"*.mp4 2>/dev/null | head -n 1)
```
Then parses with regex: `^([0-9]{4}-[0-9]{2}-[0-9]{2})_${VOD_ID}_([^_]+)_(.+)\.mp4$`

### Whisper Transcription Settings
- `vad_filter=True` with `min_silence_duration_ms=500` filters silence
- `beam_size=5` for quality vs speed balance
- SRT output simplified: only text content, no timestamps (non-standard format)

## Development Conventions

### Logging Pattern
All operations use: `echo "$VOD_ID - $timestamp - <message>" | tee -a "${logs_dir}/run-${timestamp}.log"`

### URL Validation
Strict regex: `^https://www\.twitch\.tv/videos/[0-9]+$`

### Quality Options
Valid values: `160p`, `360p`, `480p`, `720p`, `720p60`, `1080p`, `1080p60`, `source`

## Notes
- `urls.txt` batch mode: Legacy format, not actively used (main workflow uses direct URL arguments)

## Output Artifacts
- **Summaries**: AI-generated markdown files in `summaries/` using Copilot with `.github/summary-generation-prompt.md` template
- **Transcripts**: Auto-generated SRT files (unusual format - text-only, double-newline separated)
- **Logs**: All operations logged with timestamps for debugging

## Summary Generation Workflow
Use `.github/summary-generation-prompt.md` as a comprehensive template for generating stream summaries:
1. Open transcript SRT file from `transcripts/{channel}/`
2. Reference the prompt template in Copilot Chat
3. Generate structured markdown summary with trading positions, market analysis, and key takeaways
4. Save to `summaries/` with naming: `{channel}-{YYYY-MM-DD}-{title-prefix}-SUMMARY.md`

## Common Pitfall
The SRT files generated are non-standard - they lack timestamps and sequence numbers, containing only transcribed text separated by blank lines. This is due to the custom Python block in `vod-transcribe.sh`.
