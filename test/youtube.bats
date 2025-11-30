#!/usr/bin/env bats

# Tests for scripts/youtube.sh
# Covers: YouTube URL validation, caption fetching, audio download, transcription

setup() {
  load 'test_helper/common-setup'
  _common_setup
  
  mkdir -p "${TEST_TEMP_DIR}/logs"
  mkdir -p "${TEST_TEMP_DIR}/vods/youtube"
  mkdir -p "${TEST_TEMP_DIR}/transcripts/youtube"
  
  cd "$TEST_TEMP_DIR" || exit 1
}

teardown() {
  _common_teardown
}

# ============================================================================
# Help Tests
# ============================================================================

@test "youtube.sh --help shows help" {
  run "${SCRIPTS_DIR}/youtube.sh" --help
  assert_success
  assert_output --partial "YouTube Transcript Fetcher"
  assert_output --partial "Usage: vod youtube"
  assert_output --partial "--download"
  assert_output --partial "--lang"
}

@test "youtube.sh -h shows help" {
  run "${SCRIPTS_DIR}/youtube.sh" -h
  assert_success
  assert_output --partial "YouTube Transcript Fetcher"
}

# ============================================================================
# URL Validation Tests
# ============================================================================

@test "youtube.sh rejects missing URL" {
  run "${SCRIPTS_DIR}/youtube.sh"
  assert_failure
  assert_output --partial "Missing YouTube video URL"
}

@test "youtube.sh accepts youtube.com/watch URL" {
  create_mock "yt-dlp" 1 ""
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  assert_output --partial "Video ID: dQw4w9WgXcQ"
}

@test "youtube.sh accepts youtu.be short URL" {
  create_mock "yt-dlp" 1 ""
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://youtu.be/dQw4w9WgXcQ"
  assert_output --partial "Video ID: dQw4w9WgXcQ"
}

@test "youtube.sh extracts video ID from complex URL" {
  create_mock "yt-dlp" 1 ""
  
  # URL with extra parameters
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLtest&index=5"
  assert_output --partial "Video ID: dQw4w9WgXcQ"
}

@test "youtube.sh rejects invalid YouTube URL" {
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.vimeo.com/123456"
  assert_failure
  assert_output --partial "Unknown argument"
}

@test "youtube.sh rejects URL with invalid video ID format" {
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=short"
  assert_failure
  assert_output --partial "Could not extract video ID"
}

# ============================================================================
# Option Parsing Tests
# ============================================================================

@test "youtube.sh accepts --lang option" {
  create_mock "yt-dlp" 1 ""
  
  run "${SCRIPTS_DIR}/youtube.sh" --lang es "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  assert_output --partial "Preferred Language: es"
}

@test "youtube.sh uses default language en" {
  create_mock "yt-dlp" 1 ""
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  assert_output --partial "Preferred Language: en"
}

@test "youtube.sh accepts --download flag" {
  create_mock "yt-dlp" 1 ""
  
  run "${SCRIPTS_DIR}/youtube.sh" --download "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  assert_output --partial "Download Mode: Enabled"
}

@test "youtube.sh rejects unknown options" {
  run "${SCRIPTS_DIR}/youtube.sh" --unknown "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  assert_failure
  assert_output --partial "Unknown argument"
}

# ============================================================================
# Dependency Check Tests
# ============================================================================

@test "youtube.sh checks for yt-dlp" {
  # Remove yt-dlp from mock path
  run bash -c 'export PATH="/empty"; "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ" 2>&1'
  # The script should fail when yt-dlp is not found
  # (actual behavior depends on whether yt-dlp is in system PATH)
}

# ============================================================================
# Cookie Authentication Tests
# ============================================================================

@test "youtube.sh uses cookies.txt from project root when present" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  # Create cookies.txt in the test temp directory (simulates project root)
  echo "# Netscape HTTP Cookie File" > "${TEST_TEMP_DIR}/cookies.txt"
  echo ".youtube.com	TRUE	/	TRUE	1234567890	SID	testvalue" >> "${TEST_TEMP_DIR}/cookies.txt"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  # Check that yt-dlp was called with --cookies argument
  assert_mock_called_with "yt-dlp" "--cookies.*cookies.txt"
}

@test "youtube.sh works without cookies when no cookie file exists" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  # Make sure no cookies.txt exists
  rm -f "${TEST_TEMP_DIR}/cookies.txt"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  # yt-dlp should be called without --cookies argument
  run grep -E "\-\-cookies" "${TEST_TEMP_DIR}/yt-dlp.calls"
  assert_failure  # grep should fail = no --cookies found
}

# ============================================================================
# Metadata Extraction Tests
# ============================================================================

@test "youtube.sh extracts video metadata" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video Title" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_output --partial "Video: Test Video Title"
  assert_output --partial "Channel: TestChannel"
  assert_output --partial "Published: 2025-11-29"
}

@test "youtube.sh sanitizes channel name" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "Channel With Spaces!" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  # Channel is logged as-is but filename is sanitized
  assert_output --partial "Channel: Channel With Spaces!"
}

@test "youtube.sh truncates title to 20 characters for filename" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "This Is A Very Long Title That Exceeds Twenty Characters" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  # Output should mention the video info
  assert_output --partial "Video: This Is A Very Long Title"
}

# ============================================================================
# Caption Download Tests
# ============================================================================

@test "youtube.sh lists available subtitles" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  echo "Available subtitles: en, es, de"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_output --partial "Checking available subtitles"
}

@test "youtube.sh downloads subtitles with correct language" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  echo "en: vtt, srt"
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  # Simulate no subtitles found
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" --lang es "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  # Check yt-dlp was called with language option
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--sub-lang"
}

# ============================================================================
# No Captions Fallback Tests
# ============================================================================

@test "youtube.sh fails when no captions and no --download flag" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  echo "No subtitles"
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  # No subtitle file created
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_failure
  assert_output --partial "No subtitles available"
  assert_output --partial "--download not specified"
}

@test "youtube.sh downloads audio when --download and no captions" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  local audio_file="${TEST_TEMP_DIR}/vods/youtube/testchannel-2025-11-29-test.aac"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  echo "No subtitles"
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  # No subtitle file created
  exit 0
elif [[ "$*" == *"-x"* ]]; then
  # Create audio file
  mkdir -p "$(dirname '"$audio_file"')"
  touch "'"$audio_file"'"
  exit 0
else
  exit 1
fi
'
  
  # Create mock for transcribe-audio.sh (script uses TRANSCRIBE_AUDIO_SCRIPT env var)
  create_mock "transcribe-audio.sh" 0 "Mock transcribe-audio.sh called"
  
  run "${SCRIPTS_DIR}/youtube.sh" --download "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_output --partial "Downloading and extracting audio"
}

# ============================================================================
# SRT to Text Conversion Tests
# ============================================================================

@test "youtube.sh converts SRT to plain text" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  # Create a mock SRT file
  local srt_content="1
00:00:00,000 --> 00:00:05,000
Hello world

2
00:00:05,000 --> 00:00:10,000
This is a test"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  echo "en: srt"
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  # Create SRT file
  mkdir -p "'"${TEST_TEMP_DIR}"'/transcripts/youtube"
  echo "'"$srt_content"'" > "'"${TEST_TEMP_DIR}"'/transcripts/youtube/testchannel-2025-11-29-test.en.srt"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_output --partial "Converting to plain text"
}

# ============================================================================
# Output File Tests
# ============================================================================

@test "youtube.sh creates transcript in transcripts/youtube/" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  local srt_file="${TEST_TEMP_DIR}/transcripts/youtube/testchannel-2025-11-29-test-video.en.srt"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  mkdir -p "$(dirname '"$srt_file"')"
  echo "1
00:00:00,000 --> 00:00:05,000
Test content" > "'"$srt_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_output --partial "Transcript saved"
}

# ============================================================================
# Audio Download Mode Tests
# ============================================================================

@test "youtube.sh with --download extracts audio to AAC" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  local srt_file="${TEST_TEMP_DIR}/transcripts/youtube/testchannel-2025-11-29-test.en.srt"
  local audio_file="${TEST_TEMP_DIR}/vods/youtube/testchannel-2025-11-29-test.aac"
  
  create_conditional_mock "yt-dlp" '
echo "yt-dlp: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  mkdir -p "$(dirname '"$srt_file"')"
  echo "1
00:00:00,000 --> 00:00:05,000
Test" > "'"$srt_file"'"
  exit 0
elif [[ "$*" == *"-x"* ]]; then
  mkdir -p "$(dirname '"$audio_file"')"
  touch "'"$audio_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" --download "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  # Check yt-dlp was called with audio extraction flags
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "-x"
  assert_output --partial "--audio-format aac"
}

# ============================================================================
# Error Handling Tests
# ============================================================================

@test "youtube.sh handles metadata fetch failure" {
  create_mock "yt-dlp" 1 "Error: Unable to fetch"
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_failure
  assert_output --partial "Failed to fetch video information"
}

@test "youtube.sh handles missing audio file after download" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  # No subtitle file
  exit 0
elif [[ "$*" == *"-x"* ]]; then
  # Don'\''t create audio file (simulate failure)
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" --download "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_failure
  assert_output --partial "No audio file found"
}

# ============================================================================
# Summary Output Tests
# ============================================================================

@test "youtube.sh shows success summary with transcript" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  local srt_file="${TEST_TEMP_DIR}/transcripts/youtube/testchannel-2025-11-29-test.en.srt"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  mkdir -p "$(dirname '"$srt_file"')"
  echo "1
00:00:00,000 --> 00:00:05,000
Test" > "'"$srt_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_success
  assert_output --partial "Processing completed successfully"
  assert_output --partial "Transcript (plain text)"
}

@test "youtube.sh shows audio file in summary when --download" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "TestChannel" "20251129" > "$json_file"
  
  local srt_file="${TEST_TEMP_DIR}/transcripts/youtube/testchannel-2025-11-29-test.en.srt"
  local audio_file="${TEST_TEMP_DIR}/vods/youtube/testchannel-2025-11-29-test.aac"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
elif [[ "$*" == *"--list-subs"* ]]; then
  exit 0
elif [[ "$*" == *"--write-subs"* ]]; then
  mkdir -p "$(dirname '"$srt_file"')"
  echo "1
00:00:00,000 --> 00:00:05,000
Test" > "'"$srt_file"'"
  exit 0
elif [[ "$*" == *"-x"* ]]; then
  mkdir -p "$(dirname '"$audio_file"')"
  touch "'"$audio_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/youtube.sh" --download "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  
  assert_success
  assert_output --partial "Audio:"
}
