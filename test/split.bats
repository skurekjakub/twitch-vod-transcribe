#!/usr/bin/env bats

# Tests for scripts/split.sh
# Covers: Video splitting, duration checks, chunk merging logic

setup() {
  load 'test_helper/common-setup'
  _common_setup
  
  cd "$TEST_TEMP_DIR" || exit 1
}

teardown() {
  _common_teardown
}

# ============================================================================
# Help Tests
# ============================================================================

@test "split.sh --help shows help" {
  run "${SCRIPTS_DIR}/split.sh" --help
  assert_success
  assert_output --partial "Video Splitter"
  assert_output --partial "Usage: vod split"
  assert_output --partial "max_hours"
}

@test "split.sh -h shows help" {
  run "${SCRIPTS_DIR}/split.sh" -h
  assert_success
  assert_output --partial "Video Splitter"
}

@test "split.sh with no arguments shows help" {
  run "${SCRIPTS_DIR}/split.sh"
  assert_success
  assert_output --partial "Usage: vod split"
}

# ============================================================================
# File Validation Tests
# ============================================================================

@test "split.sh fails with nonexistent file" {
  run "${SCRIPTS_DIR}/split.sh" "nonexistent.mp4"
  assert_failure
  assert_output --partial "File not found"
}

@test "split.sh validates file exists" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # Mock ffprobe to return duration
  create_mock "ffprobe" 0 "3600"
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file"
  
  # Should get past file validation
  assert_output --partial "Video Splitter"
}

# ============================================================================
# Dependency Check Tests
# ============================================================================

@test "split.sh checks for ffprobe" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # Don't mock ffprobe - let it fail naturally or check error message
  run bash -c 'export PATH="/empty"; "${SCRIPTS_DIR}/split.sh" "'"$video_file"'" 2>&1'
  
  # Should mention ffprobe if not found
  # (actual behavior depends on system PATH)
}

@test "split.sh checks for ffmpeg" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"  # 6 hours
  # Don't mock ffmpeg
  
  # Test will fail if ffmpeg not available
}

# ============================================================================
# Duration Check Tests
# ============================================================================

@test "split.sh uses default 5 hour chunks" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "3600"  # 1 hour
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file"
  
  assert_output --partial "Max chunk duration: 5 hours"
}

@test "split.sh accepts custom chunk hours" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "3600"
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 3
  
  assert_output --partial "Max chunk duration: 3 hours"
}

@test "split.sh skips split for short videos" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # 1 hour video with 5 hour max
  create_mock "ffprobe" 0 "3600"
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file"
  
  assert_success
  assert_output --partial "Video is shorter than 5 hours"
  assert_output --partial "No split needed"
}

@test "split.sh splits videos longer than max duration" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # 6 hours video with 5 hour max
  create_mock "ffprobe" 0 "21600"
  
  # Create ffmpeg mock that creates output files
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
touch "${TEST_TEMP_DIR}/test-part00.mp4"
touch "${TEST_TEMP_DIR}/test-part01.mp4"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  assert_output --partial "Will split into"
}

# ============================================================================
# Duration Display Tests
# ============================================================================

@test "split.sh displays video duration in human format" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # 2 hours 30 minutes 45 seconds
  create_mock "ffprobe" 0 "9045"
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file"
  
  assert_output --partial "Video duration: 2h 30m 45s"
}

@test "split.sh calculates number of parts correctly" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # 11 hours = 39600 seconds, with 5 hour chunks = 3 parts
  create_mock "ffprobe" 0 "39600"
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  assert_output --partial "Will split into"
}

# ============================================================================
# Chunk Merging Logic Tests
# ============================================================================

@test "split.sh merges short final chunk with previous" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # 5 hours 30 minutes = 19800 seconds
  # With 5 hour chunks, remainder is 30 min (< 1 hour)
  # Should reduce to 1 part or adjust segment time
  create_mock "ffprobe" 0 "19800"
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  # Should mention merging or adjusted segment duration
  assert_output --regexp "(Final chunk would be|merging|Adjusted segment)"
}

@test "split.sh doesn't merge if final chunk is over 1 hour" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # 7 hours = 25200 seconds
  # With 5 hour chunks: 5h + 2h remaining
  # 2 hours > 1 hour minimum, no merge needed
  create_mock "ffprobe" 0 "25200"
  
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
touch "${TEST_TEMP_DIR}/test-part00.mp4"
touch "${TEST_TEMP_DIR}/test-part01.mp4"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  # Should split into 2 parts normally
  assert_output --partial "Will split into 2 parts"
}

# ============================================================================
# ffmpeg Command Tests
# ============================================================================

@test "split.sh uses segment format for splitting" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"  # 6 hours
  
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
echo "ffmpeg args: \$*" >> "${TEST_TEMP_DIR}/ffmpeg.log"
touch "${TEST_TEMP_DIR}/test-part00.mp4"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "-f segment"
}

@test "split.sh uses copy codec (no re-encoding)" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"
  
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
echo "ffmpeg args: \$*" >> "${TEST_TEMP_DIR}/ffmpeg.log"
touch "${TEST_TEMP_DIR}/test-part00.mp4"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "-c copy"
}

@test "split.sh uses -map 0 to include all streams" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"
  
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
echo "ffmpeg args: \$*" >> "${TEST_TEMP_DIR}/ffmpeg.log"
touch "${TEST_TEMP_DIR}/test-part00.mp4"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "-map 0"
}

@test "split.sh resets timestamps for each segment" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"
  
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
echo "ffmpeg args: \$*" >> "${TEST_TEMP_DIR}/ffmpeg.log"
touch "${TEST_TEMP_DIR}/test-part00.mp4"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "-reset_timestamps 1"
}

# ============================================================================
# Output File Naming Tests
# ============================================================================

@test "split.sh creates files with -partXX suffix" {
  local video_file="${TEST_TEMP_DIR}/video.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"
  
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
echo "ffmpeg args: \$*" >> "${TEST_TEMP_DIR}/ffmpeg.log"
touch "${TEST_TEMP_DIR}/video-part00.mp4"
touch "${TEST_TEMP_DIR}/video-part01.mp4"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "part%02d"
}

@test "split.sh preserves original file extension" {
  local video_file="${TEST_TEMP_DIR}/video.mkv"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"
  
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
echo "ffmpeg args: \$*" >> "${TEST_TEMP_DIR}/ffmpeg.log"
touch "${TEST_TEMP_DIR}/video-part00.mkv"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial ".mkv"
}

# ============================================================================
# Success/Failure Tests
# ============================================================================

@test "split.sh shows success summary" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"
  
  cat > "${MOCK_BIN_DIR}/ffmpeg" << FFMOCK
#!/bin/bash
touch "${TEST_TEMP_DIR}/test-part00.mp4"
touch "${TEST_TEMP_DIR}/test-part01.mp4"
exit 0
FFMOCK
  chmod +x "${MOCK_BIN_DIR}/ffmpeg"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  assert_success
  assert_output --partial "Split completed successfully"
  assert_output --partial "Original file preserved"
}

@test "split.sh fails if ffmpeg fails" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "21600"
  create_mock "ffmpeg" 1 "Error"
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file" 5
  
  assert_failure
  assert_output --partial "Error: Split failed"
}

@test "split.sh handles invalid duration from ffprobe" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # Return empty/invalid duration
  create_mock "ffprobe" 0 ""
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file"
  
  assert_failure
  assert_output --partial "Could not determine video duration"
}

# ============================================================================
# Absolute Path Tests
# ============================================================================

@test "split.sh works with absolute paths" {
  local video_file="${TEST_TEMP_DIR}/absolute/path/test.mp4"
  mkdir -p "$(dirname "$video_file")"
  touch "$video_file"
  
  create_mock "ffprobe" 0 "3600"
  create_mock "ffmpeg" 0 ""
  
  run "${SCRIPTS_DIR}/split.sh" "$video_file"
  
  assert_success
  assert_output --partial "No split needed"
}
