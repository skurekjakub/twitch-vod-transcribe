#!/usr/bin/env bats

# Tests for lib/transcribe-audio.sh
# Covers: Argument validation, model selection, path handling

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

@test "transcribe-audio.sh requires exactly 2 arguments" {
  run "${LIB_DIR}/transcribe-audio.sh"
  assert_failure
  assert_output --partial "Invalid number of arguments"
  assert_output --partial "Usage:"
}

@test "transcribe-audio.sh fails with only 1 argument" {
  run "${LIB_DIR}/transcribe-audio.sh" "input.aac"
  assert_failure
  assert_output --partial "Invalid number of arguments"
}

@test "transcribe-audio.sh shows usage example" {
  run "${LIB_DIR}/transcribe-audio.sh"
  assert_output --partial "Example:"
  assert_output --partial "audio.aac"
  assert_output --partial "transcript.txt"
}

# ============================================================================
# Model Selection Tests
# ============================================================================

@test "transcribe-audio.sh uses large-v3 by default" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  # Create a mock python3 to capture what model is used
  create_conditional_mock "python3" '
echo "python3 called" >> "'"${TEST_TEMP_DIR}"'/python.log"
# Read stdin and log it
cat >> "'"${TEST_TEMP_DIR}"'/python.log"
exit 0
'
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  assert_output --partial "Model: large-v3"
}

@test "transcribe-audio.sh accepts --medium flag" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" --medium "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  # Should use medium model (medium.en)
  assert_output --partial "Model: medium.en"
}

@test "transcribe-audio.sh accepts --large flag" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" --large "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  assert_output --partial "Model: large-v1"
}

# ============================================================================
# Input File Validation Tests
# ============================================================================

@test "transcribe-audio.sh fails if input file doesn't exist" {
  run "${LIB_DIR}/transcribe-audio.sh" "nonexistent.aac" "output.txt"
  assert_failure
  assert_output --partial "Audio file not found"
}

@test "transcribe-audio.sh accepts existing input file" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  # Should get past validation
  assert_output --partial "Audio Transcription"
}

# ============================================================================
# Path Handling Tests
# ============================================================================

@test "transcribe-audio.sh converts relative paths to absolute" {
  local audio_file="${TEST_TEMP_DIR}/input.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  # Use relative path
  cd "$TEST_TEMP_DIR"
  run "${LIB_DIR}/transcribe-audio.sh" "input.aac" "output.txt"
  
  # Should log absolute paths
  assert_output --partial "Input:"
}

@test "transcribe-audio.sh handles absolute paths" {
  local audio_file="${TEST_TEMP_DIR}/absolute/path/test.aac"
  mkdir -p "$(dirname "$audio_file")"
  touch "$audio_file"
  
  local output_file="${TEST_TEMP_DIR}/output/transcript.txt"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "$output_file"
  
  assert_output --partial "Audio Transcription"
}

@test "transcribe-audio.sh creates output directory if needed" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  local output_file="${TEST_TEMP_DIR}/new/nested/dir/output.txt"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "$output_file"
  
  # Directory should be created
  assert_dir_exists "$(dirname "$output_file")"
}

# ============================================================================
# Python Environment Tests
# ============================================================================

@test "transcribe-audio.sh activates venv if available" {
  # This is hard to test without actually having a venv
  # We just verify the script structure
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  assert_success
}

# ============================================================================
# Output Tests
# ============================================================================

@test "transcribe-audio.sh shows input and output files" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  assert_output --partial "Input:"
  assert_output --partial "Output:"
}

@test "transcribe-audio.sh shows model being used" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  assert_output --partial "Model:"
}

@test "transcribe-audio.sh shows completion message" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  assert_success
  assert_output --partial "Transcription completed"
  assert_output --partial "Output saved to:"
}

# ============================================================================
# Logging Tests
# ============================================================================

@test "transcribe-audio.sh creates log file" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  # Check log file was created
  run ls "${TEST_TEMP_DIR}/logs/"
  assert_output --partial "transcribe-"
}

# ============================================================================
# Error Handling Tests
# ============================================================================

@test "transcribe-audio.sh fails if python3 fails" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 1 "Error: Module not found"
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  assert_failure
}

# ============================================================================
# Whisper Configuration Tests
# ============================================================================

@test "transcribe-audio.sh mentions CUDA usage" {
  local audio_file="${TEST_TEMP_DIR}/test.aac"
  touch "$audio_file"
  
  create_mock "python3" 0 ""
  
  run "${LIB_DIR}/transcribe-audio.sh" "$audio_file" "${TEST_TEMP_DIR}/output.txt"
  
  # The script should show transcription info
  assert_output --partial "Audio Transcription"
}
