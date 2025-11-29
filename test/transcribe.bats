#!/usr/bin/env bats

# Tests for scripts/transcribe.sh
# Covers: Twitch VOD URL validation, download, audio extraction, transcription

setup() {
  load 'test_helper/common-setup'
  _common_setup
  
  mkdir -p "${TEST_TEMP_DIR}/logs"
  mkdir -p "${TEST_TEMP_DIR}/vods"
  mkdir -p "${TEST_TEMP_DIR}/transcripts"
  
  cd "$TEST_TEMP_DIR" || exit 1
}

teardown() {
  _common_teardown
}

# ============================================================================
# Help Tests
# ============================================================================

@test "transcribe.sh --help shows help" {
  run "${SCRIPTS_DIR}/transcribe.sh" --help
  assert_success
  assert_output --partial "Twitch VOD Transcriber"
  assert_output --partial "Usage: vod transcribe"
  assert_output --partial "--download-only"
  assert_output --partial "--quality"
}

@test "transcribe.sh -h shows help" {
  run "${SCRIPTS_DIR}/transcribe.sh" -h
  assert_success
  assert_output --partial "Twitch VOD Transcriber"
}

# ============================================================================
# URL Validation Tests
# ============================================================================

@test "transcribe.sh rejects missing URL" {
  run "${SCRIPTS_DIR}/transcribe.sh"
  assert_failure
  assert_output --partial "Invalid or missing Twitch VOD URL"
}

@test "transcribe.sh rejects non-Twitch URL" {
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.youtube.com/watch?v=test123"
  assert_failure
  # Script case statement doesn't match this URL, so it's an unknown argument
  assert_output --partial "Unknown argument"
}

@test "transcribe.sh rejects malformed Twitch URL" {
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/channel/videos"
  assert_failure
  assert_output --partial "Unknown argument"
}

@test "transcribe.sh rejects Twitch URL without video ID" {
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/"
  assert_failure
  assert_output --partial "Invalid or missing Twitch VOD URL"
}

@test "transcribe.sh accepts valid Twitch VOD URL" {
  # Mock twitch-dl to fail early
  create_mock "twitch-dl" 1 "Error"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  # Will fail because twitch-dl fails, but URL validation should pass
  assert_output --partial "VOD ID: 2588036186"
}

@test "transcribe.sh extracts VOD ID correctly" {
  create_mock "twitch-dl" 1 "Error"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/1234567890"
  assert_output --partial "VOD ID: 1234567890"
}

# ============================================================================
# Option Parsing Tests
# ============================================================================

@test "transcribe.sh accepts --quality option" {
  create_mock "twitch-dl" 1 "Error"
  
  run "${SCRIPTS_DIR}/transcribe.sh" --quality 720p "https://www.twitch.tv/videos/2588036186"
  assert_output --partial "Quality: 720p"
}

@test "transcribe.sh uses default quality 480p" {
  create_mock "twitch-dl" 1 "Error"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  assert_output --partial "Quality: 480p"
}

@test "transcribe.sh accepts --download-only flag" {
  create_mock "twitch-dl" 1 "Error"
  
  run "${SCRIPTS_DIR}/transcribe.sh" --download-only "https://www.twitch.tv/videos/2588036186"
  assert_output --partial "Mode: Download only"
}

@test "transcribe.sh accepts options in any order" {
  create_mock "twitch-dl" 1 "Error"
  
  # URL before options
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186" --quality 720p
  # Should still work - URL is positional
  assert_output --partial "VOD ID: 2588036186"
}

@test "transcribe.sh rejects unknown options" {
  run "${SCRIPTS_DIR}/transcribe.sh" --unknown-option "https://www.twitch.tv/videos/2588036186"
  assert_failure
  assert_output --partial "Unknown argument"
}

# ============================================================================
# Download Tests
# ============================================================================

@test "transcribe.sh calls twitch-dl with correct quality" {
  create_conditional_mock "twitch-dl" '
echo "twitch-dl $*" >> "'"${TEST_TEMP_DIR}"'/twitch-dl.calls"
exit 1
'
  
  run "${SCRIPTS_DIR}/transcribe.sh" --quality 1080p "https://www.twitch.tv/videos/2588036186"
  
  run cat "${TEST_TEMP_DIR}/twitch-dl.calls"
  assert_output --partial "-q 1080p"
}

@test "transcribe.sh uses max-workers 3 for download" {
  create_conditional_mock "twitch-dl" '
echo "twitch-dl $*" >> "'"${TEST_TEMP_DIR}"'/twitch-dl.calls"
exit 1
'
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  
  run cat "${TEST_TEMP_DIR}/twitch-dl.calls"
  assert_output --partial "--max-workers 3"
}

# ============================================================================
# File Naming Tests
# ============================================================================

@test "transcribe.sh parses twitch-dl filename format correctly" {
  # Create a mock downloaded file with twitch-dl naming convention
  # With VOD_ROOT_DIR set to TEST_TEMP_DIR, script will look for files there
  local mock_file="${TEST_TEMP_DIR}/2024-03-15_2588036186_testchannel_Some_Video_Title.mp4"
  
  create_conditional_mock "twitch-dl" '
# Create the file twitch-dl would create
touch "'"$mock_file"'"
exit 0
'

  # Create mocks for lib scripts (scripts use EXTRACT_AUDIO_SCRIPT and TRANSCRIBE_AUDIO_SCRIPT env vars)
  create_mock "extract-audio.sh" 0 "Mock extract-audio.sh called"
  create_mock "transcribe-audio.sh" 0 "Mock transcribe-audio.sh called"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  
  # Should find and parse the file
  assert_output --partial "Found downloaded file"
}

# ============================================================================
# Download-Only Mode Tests
# ============================================================================

@test "transcribe.sh in download-only mode skips transcription" {
  local mock_file="${TEST_TEMP_DIR}/2024-03-15_2588036186_testchannel_Test_Title.mp4"
  
  create_conditional_mock "twitch-dl" '
touch "'"$mock_file"'"
exit 0
'
  
  run "${SCRIPTS_DIR}/transcribe.sh" --download-only "https://www.twitch.tv/videos/2588036186"
  
  assert_success
  assert_output --partial "Download completed! (Download-only mode)"
  refute_output --partial "Starting transcription"
}

# ============================================================================
# Error Handling Tests
# ============================================================================

@test "transcribe.sh handles twitch-dl download failure" {
  create_mock "twitch-dl" 1 "Error: Failed to download"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  
  assert_failure
}

@test "transcribe.sh handles missing downloaded file" {
  # twitch-dl succeeds but doesn't create expected file
  create_mock "twitch-dl" 0 "Download complete"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  
  assert_failure
  assert_output --partial "Could not find downloaded file"
}

# ============================================================================
# Trap/Cleanup Tests
# ============================================================================

@test "transcribe.sh sets up cleanup trap for download phase" {
  # The script uses trap to clean up on failure
  # We can verify by checking the trap is mentioned in output on error
  create_mock "twitch-dl" 1 "Download error"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  
  assert_failure
  # Trap would clean up *.mp4 files - we can't easily test trap execution
  # but we verify the script fails appropriately
}

# ============================================================================
# Integration Tests (with mocked dependencies)
# ============================================================================

@test "transcribe.sh full workflow with mocked dependencies" {
  local vod_id="2588036186"
  local mock_file="${TEST_TEMP_DIR}/2024-03-15_${vod_id}_testchannel_Test_Video.mp4"
  
  # Mock twitch-dl
  create_conditional_mock "twitch-dl" '
touch "'"$mock_file"'"
exit 0
'
  
  run "${SCRIPTS_DIR}/transcribe.sh" --download-only "https://www.twitch.tv/videos/${vod_id}"
  
  assert_success
  assert_output --partial "Download completed"
}

# ============================================================================
# Output Structure Tests
# ============================================================================

@test "transcribe.sh creates channel-specific directories" {
  local vod_id="2588036186"
  local mock_file="${TEST_TEMP_DIR}/2024-03-15_${vod_id}_mychannel_Test.mp4"
  
  create_conditional_mock "twitch-dl" '
touch "'"$mock_file"'"
exit 0
'
  
  run "${SCRIPTS_DIR}/transcribe.sh" --download-only "https://www.twitch.tv/videos/${vod_id}"
  
  # Should move file to vods/mychannel/
  assert_output --partial "Moved to: vods/mychannel/"
}

@test "transcribe.sh shortens title to 20 characters" {
  local vod_id="2588036186"
  # Title with more than 20 characters
  local mock_file="${TEST_TEMP_DIR}/2024-03-15_${vod_id}_testchannel_This_Is_A_Very_Long_Title_That_Should_Be_Shortened.mp4"
  
  create_conditional_mock "twitch-dl" '
touch "'"$mock_file"'"
exit 0
'
  
  run "${SCRIPTS_DIR}/transcribe.sh" --download-only "https://www.twitch.tv/videos/${vod_id}"
  
  # The base_name should have shortened title
  assert_output --partial "testchannel-2024-03-15-"
}

# ============================================================================
# Log File Tests
# ============================================================================

@test "transcribe.sh creates log file" {
  create_mock "twitch-dl" 1 "Error"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  
  # Check that log files were created in TEST_TEMP_DIR (via VOD_ROOT_DIR)
  run ls "${TEST_TEMP_DIR}/logs/"
  assert_output --partial "run-"
}

@test "transcribe.sh logs VOD information" {
  create_mock "twitch-dl" 1 "Error"
  
  run "${SCRIPTS_DIR}/transcribe.sh" "https://www.twitch.tv/videos/2588036186"
  
  # Output should contain the header information
  assert_output --partial "Twitch VOD Transcriber"
  assert_output --partial "VOD ID: 2588036186"
}
