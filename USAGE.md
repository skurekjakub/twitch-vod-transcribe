# Usage Guide

## Quick Start: Download and Transcribe Twitch VODs

### One-Step Process (Recommended)

Use the `vod-transcribe.sh` script to download and transcribe in one command:

```bash
./vod-transcribe.sh https://www.twitch.tv/videos/2588036186
```

This script will:
1. Download the VOD at 480p (optimal for audio extraction)
2. Extract audio from the video
3. Transcribe to English subtitles using **Whisper large-v3** (CUDA-accelerated)

### Output Files:

After processing, you'll have:
- `2588036186.mp4` - downloaded video (480p)
- `2588036186.aac` - extracted audio
- `transcripts/2588036186/2588036186-en.srt` - English subtitles

All transcripts are organized in the `transcripts/` folder, with each VOD getting its own subfolder.

---

## Alternative: Manual Two-Step Process

### Step 1: Download a Twitch VOD

Use the `download_vod.py` script to download a video at 480p:

```bash
python download_vod.py https://www.twitch.tv/videos/2588036186
```

This will download the video with the VOD ID as the filename (e.g., `2588036186.mp4`).

### Step 2: Transcribe the Downloaded Video

Use the `transcribe.sh` script to process the video:

#### English only transcription:
```bash
./transcribe.sh 2588036186.mp4 --english-only
```

#### Both English and German transcription:
```bash
./transcribe.sh 2588036186.mp4
```

---

## Batch Processing

### Original Batch Mode

If you have multiple videos in `urls.txt`:
```bash
./transcribe.sh
```

Or to only download without transcribing:
```bash
./transcribe.sh --download-only
```

Format for `urls.txt`:
```
VOD_ID;DIRECT_VIDEO_URL
738103227;https://di2joen6szy7h.cloudfront.net/738103227/chunked/index-dvr.m3u8
```

---

## Requirements

### System Dependencies:
- **ffmpeg** - for audio/video processing
  ```bash
  sudo apt install ffmpeg
  ```
- **CUDA** (optional but recommended) - for GPU-accelerated transcription
  - With CUDA: ~30-60 min for 4-hour VOD
  - Without CUDA: ~2-4 hours for 4-hour VOD

### Python Dependencies:
- **Python 3.x** with packages from `requirements.txt`
  ```bash
  pip install -r requirements.txt
  ```
  This includes:
  - `twitch-dl` - for downloading Twitch VODs
  - `faster-whisper` - for state-of-the-art speech-to-text transcription

### Whisper Models:
The script uses **OpenAI Whisper large-v3** model which provides:
- ✅ Superior accuracy compared to Vosk
- ✅ Proper punctuation and capitalization
- ✅ Better handling of gaming/streaming terminology
- ✅ Automatic language detection
- ✅ Models download automatically on first run (~3GB)
- ✅ Cached in `~/.cache/huggingface/hub/`

Available models (can be changed in script):
- `tiny` - Fastest, lowest accuracy (~1GB VRAM)
- `base` - Fast, decent accuracy (~1GB VRAM)
- `small` - Good balance (~2GB VRAM)
- `medium` - Better quality (~5GB VRAM)
- `large-v2` - Excellent quality (~10GB VRAM)
- `large-v3` - **Best quality** (~10GB VRAM) - **Default**

---

## GPU Acceleration

The script automatically uses CUDA if available:
- **RTX A2000 (8GB VRAM)**: Can run `large-v3` with `float16`
- **Lower VRAM GPUs**: Use `medium` or `small` models
- **CPU-only systems**: Falls back to CPU (slower but works)

To modify GPU settings, edit `vod-transcribe.sh`:
```python
# Change model size:
model = WhisperModel("medium", device="cuda", compute_type="float16")

# For CPU only:
model = WhisperModel("medium", device="cpu", compute_type="int8")
```

---

## Directory Structure

After running the scripts, your directory will look like:

```
twitch-vod-transcribe/
├── vod-transcribe.sh          # One-step download + transcribe script
├── download_vod.py            # Standalone download script
├── transcribe.sh              # Standalone transcribe script (legacy Vosk)
├── requirements.txt           # Python dependencies
├── 2588036186.mp4             # Downloaded video
├── 2588036186.aac             # Extracted audio
└── transcripts/               # All transcripts organized here
    └── 2588036186/
        └── 2588036186-en.srt  # English subtitles
```

**Note**: The old Vosk models (`vosk-model-en-us-0.22/`) are no longer needed and can be removed.
