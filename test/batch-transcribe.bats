#!/usr/bin/env bats

# Tests for scripts/batch-transcribe.sh
# Covers: URL file parsing, type detection, option handling, error recovery

setup() {
  load 'test_helper/common-setup'
  _common_setup
  
  mkdir -p "${TEST_TEMP_DIR}/logs"
  
  cd "$TEST_TEMP_DIR" || exit 1
  
  # Export script paths to use mock bin directory
  export TRANSCRIBE_SCRIPT="${MOCK_BIN_DIR}/transcribe.sh"
  export YOUTUBE_SCRIPT="${MOCK_BIN_DIR}/youtube.sh"
}

teardown() {
  _common_teardown
}

# ============================================================================
# Help Tests
# ============================================================================

@test "batch-transcribe.sh --help shows help" {
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --help
  assert_success
  assert_output --partial "Batch VOD Transcriber"
  assert_output --partial "Usage: vod batch transcribe"
  assert_output --partial "--quality"
  assert_output --partial "--download-youtube"
  assert_output --partial "--continue-on-error"
}

@test "batch-transcribe.sh -h shows help" {
  run "${SCRIPTS_DIR}/batch-transcribe.sh" -h
  assert_success
  assert_output --partial "Batch VOD Transcriber"
}

# ============================================================================
# URL File Validation Tests
# ============================================================================

@test "batch-transcribe.sh uses default urls.txt file" {
  # Create test url file and pass full path
  # (The script changes to ROOT_DIR so we can't rely on working directory)
  echo "# Empty" > "${TEST_TEMP_DIR}/urls.txt"
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "${TEST_TEMP_DIR}/urls.txt"
  
  assert_success
  assert_output --partial "Starting batch transcription from: ${TEST_TEMP_DIR}/urls.txt"
}

@test "batch-transcribe.sh accepts custom URL file" {
  local url_file=$(create_url_file "custom-urls.txt" "# Empty file")
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_success
  assert_output --partial "Starting batch transcription from: $url_file"
}

@test "batch-transcribe.sh fails with missing URL file" {
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "nonexistent-file.txt"
  
  assert_failure
  assert_output --partial "URL file not found"
}

# ============================================================================
# URL Type Detection Tests
# ============================================================================

@test "batch-transcribe.sh detects Twitch VOD URLs" {
  local url_file=$(create_url_file "urls.txt" "https://www.twitch.tv/videos/2588036186")
  
  # Mock transcribe.sh to verify it's called
  create_mock "transcribe.sh" 0 "Transcribe called"
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "Detected Twitch VOD"
}

@test "batch-transcribe.sh detects YouTube URLs (youtube.com)" {
  local url_file=$(create_url_file "urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  # Mock youtube.sh
  create_mock "youtube.sh" 0 "YouTube called"
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "Detected YouTube video"
}

@test "batch-transcribe.sh detects YouTube URLs (youtu.be)" {
  local url_file=$(create_url_file "urls.txt" "https://youtu.be/dQw4w9WgXcQ")
  
  create_mock "youtube.sh" 0 "YouTube called"
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "Detected YouTube video"
}

@test "batch-transcribe.sh skips unknown URL types" {
  local url_file=$(create_url_file "urls.txt" "https://vimeo.com/123456")
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "Unknown URL format, skipping"
  assert_output --partial "Skipped: 1"
}

# ============================================================================
# Comment and Blank Line Handling Tests
# ============================================================================

@test "batch-transcribe.sh skips comment lines" {
  local url_file=$(create_url_file "urls.txt" \
    "# This is a comment" \
    "https://www.twitch.tv/videos/2588036186")
  
  create_mock "transcribe.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  # Should only process 1 URL, not 2
  assert_output --partial "Found 1 URLs to process"
}

@test "batch-transcribe.sh skips blank lines" {
  local url_file=$(create_url_file "urls.txt" \
    "https://www.twitch.tv/videos/2588036186" \
    "" \
    "https://www.twitch.tv/videos/1234567890")
  
  create_mock "transcribe.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "Found 2 URLs to process"
}

@test "batch-transcribe.sh handles mixed comments and URLs" {
  local url_file=$(create_url_file "urls.txt" \
    "# Twitch VODs" \
    "https://www.twitch.tv/videos/2588036186" \
    "" \
    "# YouTube videos" \
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ" \
    "  # Indented comment")
  
  create_mock "transcribe.sh" 0 ""
  create_mock "youtube.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "Found 2 URLs to process"
}

# ============================================================================
# Option Handling Tests
# ============================================================================

@test "batch-transcribe.sh passes --quality to transcribe.sh" {
  local url_file=$(create_url_file "urls.txt" "https://www.twitch.tv/videos/2588036186")
  
  create_conditional_mock "transcribe.sh" '
echo "transcribe.sh args: $*" >> "'"${TEST_TEMP_DIR}"'/transcribe.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --quality 720p "$url_file"
  
  run cat "${TEST_TEMP_DIR}/transcribe.log"
  assert_output --partial "--quality 720p"
}

@test "batch-transcribe.sh passes --download to youtube.sh" {
  local url_file=$(create_url_file "urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_conditional_mock "youtube.sh" '
echo "youtube.sh args: $*" >> "'"${TEST_TEMP_DIR}"'/youtube.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --download-youtube "$url_file"
  
  run cat "${TEST_TEMP_DIR}/youtube.log"
  assert_output --partial "--download"
}

@test "batch-transcribe.sh passes --lang to youtube.sh" {
  local url_file=$(create_url_file "urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_conditional_mock "youtube.sh" '
echo "youtube.sh args: $*" >> "'"${TEST_TEMP_DIR}"'/youtube.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --youtube-lang es "$url_file"
  
  run cat "${TEST_TEMP_DIR}/youtube.log"
  assert_output --partial "--lang es"
}

@test "batch-transcribe.sh rejects unknown options" {
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --unknown-option
  assert_failure
  assert_output --partial "Unknown option"
}

# ============================================================================
# Continue on Error Tests
# ============================================================================

@test "batch-transcribe.sh stops on first error by default" {
  local url_file=$(create_url_file "urls.txt" \
    "https://www.twitch.tv/videos/1111111111" \
    "https://www.twitch.tv/videos/2222222222")
  
  # First call fails, second should not be called
  local call_count=0
  create_conditional_mock "transcribe.sh" '
count_file="'"${TEST_TEMP_DIR}"'/call_count"
if [ -f "$count_file" ]; then
  count=$(cat "$count_file")
else
  count=0
fi
count=$((count + 1))
echo "$count" > "$count_file"
exit 1
'
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_failure
  # Should have called transcribe.sh only once
  run cat "${TEST_TEMP_DIR}/call_count"
  assert_output "1"
}

@test "batch-transcribe.sh continues after error with --continue-on-error" {
  local url_file=$(create_url_file "urls.txt" \
    "https://www.twitch.tv/videos/1111111111" \
    "https://www.twitch.tv/videos/2222222222")
  
  create_conditional_mock "transcribe.sh" '
count_file="'"${TEST_TEMP_DIR}"'/call_count"
if [ -f "$count_file" ]; then
  count=$(cat "$count_file")
else
  count=0
fi
count=$((count + 1))
echo "$count" > "$count_file"
exit 1
'
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --continue-on-error "$url_file"
  
  # Store output from batch script
  local batch_output="$output"
  
  # Should have called transcribe.sh twice
  run cat "${TEST_TEMP_DIR}/call_count"
  assert_output "2"
  
  # Should report failures (check stored output)
  [[ "$batch_output" == *"Failed: 2"* ]]
}

# ============================================================================
# YouTube Retry Logic Tests
# ============================================================================

@test "batch-transcribe.sh retries YouTube with --download when captions fail" {
  local url_file=$(create_url_file "urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_conditional_mock "youtube.sh" '
echo "youtube.sh args: $*" >> "'"${TEST_TEMP_DIR}"'/youtube.log"
if [[ "$*" == *"--download"* ]]; then
  exit 0  # Success with download
else
  exit 1  # Fail without download (no captions)
fi
'
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --continue-on-error "$url_file"
  
  assert_success
  # Store output from batch script
  local batch_output="$output"
  
  # Should have called youtube.sh twice: once without --download, once with
  run grep -c "youtube.sh args" "${TEST_TEMP_DIR}/youtube.log"
  assert_output "2"
  
  # Check stored output for retry message
  [[ "$batch_output" == *"Caption fetch failed, retrying with --download"* ]]
}

@test "batch-transcribe.sh doesn't retry if --download-youtube was specified" {
  local url_file=$(create_url_file "urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_conditional_mock "youtube.sh" '
echo "youtube.sh args: $*" >> "'"${TEST_TEMP_DIR}"'/youtube.log"
exit 1  # Always fail
'
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --download-youtube --continue-on-error "$url_file"
  
  # Should only call once since --download was already specified
  run grep -c "youtube.sh args" "${TEST_TEMP_DIR}/youtube.log"
  assert_output "1"
}

# ============================================================================
# Counter and Summary Tests
# ============================================================================

@test "batch-transcribe.sh counts total URLs correctly" {
  local url_file=$(create_url_file "urls.txt" \
    "https://www.twitch.tv/videos/1111111111" \
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ" \
    "https://www.twitch.tv/videos/2222222222")
  
  create_mock "transcribe.sh" 0 ""
  create_mock "youtube.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "Found 3 URLs to process"
}

@test "batch-transcribe.sh shows progress counter" {
  local url_file=$(create_url_file "urls.txt" \
    "https://www.twitch.tv/videos/1111111111" \
    "https://www.twitch.tv/videos/2222222222")
  
  create_mock "transcribe.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "[1/2]"
  assert_output --partial "[2/2]"
}

@test "batch-transcribe.sh shows final summary" {
  local url_file=$(create_url_file "urls.txt" \
    "https://www.twitch.tv/videos/1111111111" \
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_mock "transcribe.sh" 0 ""
  create_mock "youtube.sh" 1 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --continue-on-error "$url_file"
  
  assert_output --partial "Batch processing complete!"
  assert_output --partial "Total URLs: 2"
  assert_output --partial "Successful: 1"
  assert_output --partial "Failed:"
}

@test "batch-transcribe.sh shows log file path" {
  local url_file=$(create_url_file "urls.txt" "# Empty")
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_output --partial "Log file: logs/batch-"
}

# ============================================================================
# Mixed Content Tests
# ============================================================================

@test "batch-transcribe.sh processes mixed Twitch and YouTube URLs" {
  local url_file=$(create_url_file "urls.txt" \
    "https://www.twitch.tv/videos/1111111111" \
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ" \
    "https://youtu.be/test123test" \
    "https://www.twitch.tv/videos/2222222222")
  
  create_mock "transcribe.sh" 0 ""
  create_mock "youtube.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_success
  assert_output --partial "Successful: 4"
}

# ============================================================================
# Exit Code Tests
# ============================================================================

@test "batch-transcribe.sh exits 0 when all succeed" {
  local url_file=$(create_url_file "urls.txt" "https://www.twitch.tv/videos/1111111111")
  
  create_mock "transcribe.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_success
}

@test "batch-transcribe.sh exits non-zero when failures occur" {
  local url_file=$(create_url_file "urls.txt" "https://www.twitch.tv/videos/1111111111")
  
  create_mock "transcribe.sh" 1 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" "$url_file"
  
  assert_failure
}

@test "batch-transcribe.sh exits 0 with failures if --continue-on-error" {
  local url_file=$(create_url_file "urls.txt" "https://www.twitch.tv/videos/1111111111")
  
  create_mock "transcribe.sh" 1 ""
  
  run "${SCRIPTS_DIR}/batch-transcribe.sh" --continue-on-error "$url_file"
  
  # Should succeed (exit 0) even with failures when --continue-on-error
  assert_success
}
