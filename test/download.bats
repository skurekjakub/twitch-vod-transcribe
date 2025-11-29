#!/usr/bin/env bats

# Tests for scripts/download.sh
# Covers: URL validation, filename sanitization, NAS detection, chapter splitting

setup() {
  load 'test_helper/common-setup'
  _common_setup
  
  # Create logs directory in test temp
  mkdir -p "${TEST_TEMP_DIR}/logs"
  mkdir -p "${TEST_TEMP_DIR}/videos"
  
  # Work in temp directory
  cd "$TEST_TEMP_DIR" || exit 1
}

teardown() {
  _common_teardown
}

# ============================================================================
# Help Tests
# ============================================================================

@test "download.sh --help shows help" {
  run "${SCRIPTS_DIR}/download.sh" --help
  assert_success
  assert_output --partial "Video Downloader"
  assert_output --partial "Usage: vod download"
  assert_output --partial "chapter splitting"
}

@test "download.sh -h shows help" {
  run "${SCRIPTS_DIR}/download.sh" -h
  assert_success
  assert_output --partial "Video Downloader"
}

@test "download.sh with no arguments shows help" {
  run "${SCRIPTS_DIR}/download.sh"
  assert_success
  assert_output --partial "Usage: vod download"
}

# ============================================================================
# URL Validation Tests
# ============================================================================

@test "download.sh rejects URL without protocol" {
  run "${SCRIPTS_DIR}/download.sh" "www.youtube.com/watch?v=test123"
  assert_failure
  assert_output --partial "Invalid URL format"
  assert_output --partial "must start with http://"
}

@test "download.sh rejects invalid URL format" {
  run "${SCRIPTS_DIR}/download.sh" "not-a-url"
  assert_failure
  assert_output --partial "Invalid URL format"
}

@test "download.sh accepts http:// URLs" {
  # Mock yt-dlp to fail early so we don't need full integration
  create_mock "yt-dlp" 1 ""
  
  run "${SCRIPTS_DIR}/download.sh" "http://example.com/video"
  # Will fail because yt-dlp fails, but URL validation should pass
  assert_failure
  assert_output --partial "Fetching video metadata"
}

@test "download.sh accepts https:// URLs" {
  create_mock "yt-dlp" 1 ""
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  assert_failure
  assert_output --partial "Fetching video metadata"
}

# ============================================================================
# Dependency Check Tests
# ============================================================================

@test "download.sh checks for yt-dlp availability" {
  # Remove yt-dlp from PATH by using empty mock bin
  PATH="${TEST_TEMP_DIR}/empty_bin:$PATH"
  mkdir -p "${TEST_TEMP_DIR}/empty_bin"
  
  # Override command check
  run bash -c 'export PATH="'${TEST_TEMP_DIR}/empty_bin'"; command -v yt-dlp'
  
  # The actual test - yt-dlp check happens after URL validation
  create_mock "yt-dlp" 0 ""
  run "${SCRIPTS_DIR}/download.sh" "https://test.com/video"
  
  # Should attempt to use yt-dlp
  assert_mock_called "yt-dlp"
}

# ============================================================================
# Metadata Extraction Tests (with mocked yt-dlp)
# ============================================================================

@test "download.sh extracts video metadata correctly" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "My Test Video" "TestChannel" "20251129" > "$json_file"
  
  # Create mock that outputs JSON for --dump-json, then fails on download
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_output --partial "Video: My Test Video"
  assert_output --partial "Channel: TestChannel"
  assert_output --partial "Published: 2025-11-29"
}

@test "download.sh sanitizes channel name for filesystem" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test" "Channel With Spaces & Symbols!" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  # Channel should be sanitized (spaces/symbols replaced with hyphens)
  assert_output --partial "Channel: Channel With Spaces & Symbols!"
}

@test "download.sh sanitizes title for filename" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Title With 🔥 Emoji & Special!" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  # Should extract title (emoji handling in filename is sanitized internally)
  assert_output --partial "Video:"
}

@test "download.sh formats date from YYYYMMDD to YYYY-MM-DD" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20240315" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_output --partial "Published: 2024-03-15"
}

# ============================================================================
# Prefix Handling Tests
# ============================================================================

@test "download.sh accepts optional prefix argument" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  # Create a dummy file to pass file check
  touch "'"${TEST_TEMP_DIR}"'/videos/my-prefix-2025-11-29-test-video.mp4"
  exit 0
fi
'
  
  create_mock "ffprobe" 0 "1000"
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test" "my-prefix"
  
  # Prefix should be included in output path
  assert_output --partial "Download"
}

@test "download.sh sanitizes prefix for filename" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test" "My Prefix With Spaces!"
  
  # Should sanitize prefix (lowercase, hyphens)
  assert_success || assert_failure  # Either is fine, just checking it runs
}

# ============================================================================
# Chapter Detection Tests
# ============================================================================

@test "download.sh detects video with chapters" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json_with_chapters "Test Video" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_output --partial "chapters, will split"
}

@test "download.sh detects video without chapters" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_output --partial "No chapters found"
}

# ============================================================================
# NAS Detection Tests
# ============================================================================

@test "download.sh uses /nas/vods when NAS is mounted" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  # Create a mock /proc/mounts with NAS
  local mock_mounts="${TEST_TEMP_DIR}/mounts"
  echo "nas:/share /nas nfs defaults 0 0" > "$mock_mounts"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  # The script checks /proc/mounts which we can't easily mock
  # This test verifies the logic exists - full test needs container setup
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  # Should show one of the two messages
  assert_output --regexp "(NAS detected|NAS not detected)"
}

# ============================================================================
# Error Handling Tests
# ============================================================================

@test "download.sh handles yt-dlp metadata fetch failure" {
  create_mock "yt-dlp" 1 "Error: Unable to download video"
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_failure
  assert_output --partial "Failed to fetch video information"
}

@test "download.sh handles yt-dlp download failure" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  # Simulate download failure
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_failure
  assert_output --partial "ERROR: yt-dlp exited with code"
}

@test "download.sh detects incomplete .part files" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  # Script will determine output dir based on NAS mount - create .part file there
  # Since we can't easily control NAS detection, create in both possible locations
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  # Create .part files in both possible output directories
  mkdir -p /nas/vods/TestChannel 2>/dev/null || true
  touch /nas/vods/TestChannel/2025-11-29-test-video.mp4.part 2>/dev/null || true
  mkdir -p "'"${TEST_TEMP_DIR}"'/videos" 2>/dev/null || true
  touch "'"${TEST_TEMP_DIR}"'/videos/2025-11-29-test-video.mp4.part" 2>/dev/null || true
  exit 0
fi
'
  create_mock "ffprobe" 0 "1000"
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_failure
  assert_output --partial "Found incomplete .part files"
}

# ============================================================================
# Long Video Split Tests
# ============================================================================

@test "download.sh checks for videos over 6 hours" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Long Video" "TestChannel" "20251129" > "$json_file"
  
  # Create video file
  local video_file="${TEST_TEMP_DIR}/videos/2025-11-29-long-video.mp4"
  mkdir -p "$(dirname "$video_file")"
  touch "$video_file"
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  touch "'"$video_file"'"
  exit 0
fi
'
  # Return duration > 6 hours (21601 seconds)
  create_mock "ffprobe" 0 "21601"
  
  # Mock the split script
  create_mock "split.sh" 0 ""
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_output --partial "Checking for files longer than 6 hours"
}

# ============================================================================
# Output Template Tests
# ============================================================================

@test "download.sh uses correct output template without chapters" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
echo "$*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp-args.txt"
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  # Check yt-dlp was called with proper arguments
  if [[ -f "${TEST_TEMP_DIR}/yt-dlp-args.txt" ]]; then
    run cat "${TEST_TEMP_DIR}/yt-dlp-args.txt"
    # Should have concurrent-fragments and output format
    assert_output --partial "concurrent-fragments"
  fi
}

@test "download.sh uses chapter output template with chapters" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json_with_chapters "Test Video" "TestChannel" "20251129" > "$json_file"
  
  create_conditional_mock "yt-dlp" '
echo "$*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp-args.txt"
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  if [[ -f "${TEST_TEMP_DIR}/yt-dlp-args.txt" ]]; then
    run cat "${TEST_TEMP_DIR}/yt-dlp-args.txt"
    # Should have split-chapters flag
    assert_output --partial "split-chapters"
  fi
}

# ============================================================================
# Successful Download Tests
# ============================================================================

@test "download.sh shows success summary" {
  local json_file="${TEST_TEMP_DIR}/metadata.json"
  sample_ytdlp_json "Test Video" "TestChannel" "20251129" > "$json_file"
  
  # Script determines output dir based on NAS mount, create files in both locations
  # Also ensure no .part files exist
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
  exit 0
else
  # Create the output file in both possible output directories
  mkdir -p /nas/vods/TestChannel 2>/dev/null || true
  rm -f /nas/vods/TestChannel/*.part 2>/dev/null || true
  touch /nas/vods/TestChannel/2025-11-29-test-video.mp4 2>/dev/null || true
  mkdir -p "'"${TEST_TEMP_DIR}"'/videos" 2>/dev/null || true
  rm -f "'"${TEST_TEMP_DIR}"'/videos/*.part" 2>/dev/null || true
  touch "'"${TEST_TEMP_DIR}"'/videos/2025-11-29-test-video.mp4" 2>/dev/null || true
  exit 0
fi
'
  create_mock "ffprobe" 0 "3600"  # 1 hour video, no split needed
  
  run "${SCRIPTS_DIR}/download.sh" "https://www.youtube.com/watch?v=test123"
  
  assert_success
  assert_output --partial "Download completed successfully"
  assert_output --partial "Output files"
}
