#!/usr/bin/env bats

# Tests for lib/extract-audio.sh
# Covers: Argument validation, path handling, ffmpeg execution

setup() {
  load 'test_helper/common-setup'
  _common_setup
  
  mkdir -p "${TEST_TEMP_DIR}/logs"
  
  cd "$TEST_TEMP_DIR" || exit 1
}

teardown() {
  _common_teardown
}

# ============================================================================
# Argument Validation Tests
# ============================================================================

@test "extract-audio.sh requires exactly 2 arguments" {
  run "${LIB_DIR}/extract-audio.sh"
  assert_failure
  assert_output --partial "Invalid number of arguments"
  assert_output --partial "Usage:"
}

@test "extract-audio.sh fails with only 1 argument" {
  run "${LIB_DIR}/extract-audio.sh" "input.mp4"
  assert_failure
  assert_output --partial "Invalid number of arguments"
}

@test "extract-audio.sh fails with more than 2 arguments" {
  run "${LIB_DIR}/extract-audio.sh" "input.mp4" "output.aac" "extra"
  assert_failure
  assert_output --partial "Invalid number of arguments"
}

@test "extract-audio.sh shows usage example" {
  run "${LIB_DIR}/extract-audio.sh"
  assert_output --partial "Example:"
  assert_output --partial "video.mp4"
  assert_output --partial "audio.aac"
}

# ============================================================================
# Input File Validation Tests
# ============================================================================

@test "extract-audio.sh fails if input file doesn't exist" {
  run "${LIB_DIR}/extract-audio.sh" "nonexistent.mp4" "output.aac"
  assert_failure
  assert_output --partial "Video file not found"
}

@test "extract-audio.sh accepts existing input file" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffmpeg" 0 ""
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  # Should get past validation
  assert_output --partial "Audio Extraction"
}

# ============================================================================
# Path Handling Tests
# ============================================================================

@test "extract-audio.sh converts relative paths to absolute" {
  # Create a file in temp dir with relative name
  local video_file="${TEST_TEMP_DIR}/input.mp4"
  touch "$video_file"
  
  create_conditional_mock "ffmpeg" '
echo "ffmpeg args: $*" >> "'"${TEST_TEMP_DIR}"'/ffmpeg.log"
exit 0
'
  
  # Use relative path
  cd "$TEST_TEMP_DIR"
  run "${LIB_DIR}/extract-audio.sh" "input.mp4" "output.aac"
  
  # Should work with relative path converted to absolute
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  # The path should be absolute
  assert_output --partial "${TEST_TEMP_DIR}"
}

@test "extract-audio.sh handles absolute paths" {
  local video_file="${TEST_TEMP_DIR}/absolute/path/test.mp4"
  mkdir -p "$(dirname "$video_file")"
  touch "$video_file"
  
  local output_file="${TEST_TEMP_DIR}/output/audio.aac"
  
  create_mock "ffmpeg" 0 ""
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "$output_file"
  
  assert_output --partial "Audio Extraction"
}

@test "extract-audio.sh creates output directory if needed" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  local output_file="${TEST_TEMP_DIR}/new/nested/dir/output.aac"
  
  create_mock "ffmpeg" 0 ""
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "$output_file"
  
  # Directory should be created
  assert_dir_exists "$(dirname "$output_file")"
}

# ============================================================================
# Dependency Check Tests
# ============================================================================

@test "extract-audio.sh checks for ffmpeg" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  # Create PATH with no ffmpeg
  run bash -c 'export PATH="/nonexistent"; "${LIB_DIR}/extract-audio.sh" "'"$video_file"'" "output.aac" 2>&1'
  
  assert_failure
  assert_output --partial "ffmpeg is not installed"
}

# ============================================================================
# ffmpeg Command Tests
# ============================================================================

@test "extract-audio.sh uses -vn to skip video" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_conditional_mock "ffmpeg" '
echo "ffmpeg args: $*" >> "'"${TEST_TEMP_DIR}"'/ffmpeg.log"
exit 0
'
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "-vn"
}

@test "extract-audio.sh uses -acodec copy (no re-encoding)" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_conditional_mock "ffmpeg" '
echo "ffmpeg args: $*" >> "'"${TEST_TEMP_DIR}"'/ffmpeg.log"
exit 0
'
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "-acodec copy"
}

@test "extract-audio.sh uses -loglevel error for quiet operation" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_conditional_mock "ffmpeg" '
echo "ffmpeg args: $*" >> "'"${TEST_TEMP_DIR}"'/ffmpeg.log"
exit 0
'
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "-loglevel error"
}

@test "extract-audio.sh uses -stats for progress" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_conditional_mock "ffmpeg" '
echo "ffmpeg args: $*" >> "'"${TEST_TEMP_DIR}"'/ffmpeg.log"
exit 0
'
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  run cat "${TEST_TEMP_DIR}/ffmpeg.log"
  assert_output --partial "-stats"
}

# ============================================================================
# Output Tests
# ============================================================================

@test "extract-audio.sh shows input and output files" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffmpeg" 0 ""
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  assert_output --partial "Input:"
  assert_output --partial "Output:"
}

@test "extract-audio.sh shows completion message" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffmpeg" 0 ""
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  assert_success
  assert_output --partial "Audio extraction completed"
  assert_output --partial "Output saved to:"
}

# ============================================================================
# Logging Tests
# ============================================================================

@test "extract-audio.sh creates log file" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffmpeg" 0 ""
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  # Check log file was created
  run ls "${TEST_TEMP_DIR}/logs/"
  assert_output --partial "extract-"
}

# ============================================================================
# Error Handling Tests
# ============================================================================

@test "extract-audio.sh fails if ffmpeg fails" {
  local video_file="${TEST_TEMP_DIR}/test.mp4"
  touch "$video_file"
  
  create_mock "ffmpeg" 1 "Error: Invalid input"
  
  run "${LIB_DIR}/extract-audio.sh" "$video_file" "${TEST_TEMP_DIR}/output.aac"
  
  assert_failure
}
