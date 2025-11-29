#!/usr/bin/env bats

# Tests for scripts/list.sh
# Covers: Twitch channel URL building, output formats, options

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

@test "list.sh --help shows help" {
  run "${SCRIPTS_DIR}/list.sh" --help
  assert_success
  assert_output --partial "List Twitch VODs"
  assert_output --partial "Usage: vod list"
  assert_output --partial "--urls-only"
  assert_output --partial "--limit"
  assert_output --partial "--chapters"
}

@test "list.sh -h shows help" {
  run "${SCRIPTS_DIR}/list.sh" -h
  assert_success
  assert_output --partial "List Twitch VODs"
}

@test "list.sh with no arguments shows help" {
  run "${SCRIPTS_DIR}/list.sh"
  assert_success
  assert_output --partial "Usage: vod list"
}

# ============================================================================
# Channel URL Building Tests
# ============================================================================

@test "list.sh builds correct Twitch URL from channel name" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "forsen" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "twitch.tv/forsen/videos?filter=archives"
}

@test "list.sh uses filter=archives for VODs only" {
  create_conditional_mock "yt-dlp" '
echo "$*" >> "'"${TEST_TEMP_DIR}"'/args.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel"
  
  run cat "${TEST_TEMP_DIR}/args.log"
  assert_output --partial "filter=archives"
}

# ============================================================================
# Option Parsing Tests
# ============================================================================

@test "list.sh accepts --urls-only flag" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--print url"* ]]; then
  echo "https://www.twitch.tv/videos/123"
  echo "https://www.twitch.tv/videos/456"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --urls-only
  
  assert_success
  # Should output just URLs
  assert_output --partial "https://www.twitch.tv/videos/"
}

@test "list.sh accepts --limit option" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --limit 10
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--playlist-end 10"
}

@test "list.sh accepts --json flag" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  echo "{\"title\": \"Test VOD\"}"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --json
  
  assert_success
}

@test "list.sh accepts --chapters flag" {
  create_mock "yt-dlp" 0 ""
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --chapters --limit 1
  
  # Should mention chapters in output
  assert_output --partial "Fetching VODs with chapter info"
}

@test "list.sh rejects unknown options" {
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --unknown
  
  assert_failure
  assert_output --partial "Unknown option"
}

# ============================================================================
# Output Format Tests
# ============================================================================

@test "list.sh human-readable format uses flat-playlist" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel"
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--flat-playlist"
}

@test "list.sh urls-only mode uses --print url" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--print url"
}

# ============================================================================
# Chapters Mode Tests
# ============================================================================

@test "list.sh chapters mode uses --dump-json" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --chapters
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--dump-json"
}

@test "list.sh chapters mode parses chapter info" {
  # Write JSON to a file to avoid shell quoting issues
  local json_file="${TEST_TEMP_DIR}/vod.json"
  cat > "$json_file" << 'JSONEOF'
{"title": "Test VOD", "webpage_url": "https://www.twitch.tv/videos/123", "duration_string": "2:00:00", "upload_date": "20251129", "chapters": [{"title": "Chapter 1", "start_time": 0}, {"title": "Chapter 2", "start_time": 3600}]}
JSONEOF
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --chapters --limit 1
  
  assert_output --partial "Chapter"
  assert_output --partial "Test VOD"
}

@test "list.sh shows 'No chapters found' when none exist" {
  local json='{"title": "Test VOD", "webpage_url": "https://www.twitch.tv/videos/123", "duration_string": "2:00:00", "upload_date": "20251129"}'
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  echo "'"$json"'"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --chapters --limit 1
  
  assert_output --partial "No chapters found"
}

# ============================================================================
# Date Formatting Tests
# ============================================================================

@test "list.sh formats upload date correctly in chapters mode" {
  # Write JSON to a file to avoid shell quoting issues
  local json_file="${TEST_TEMP_DIR}/vod.json"
  cat > "$json_file" << 'JSONEOF'
{"title": "Test", "webpage_url": "https://test.com", "duration_string": "1:00:00", "upload_date": "20240315"}
JSONEOF
  
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  cat "'"$json_file"'"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --chapters --limit 1
  
  assert_output --partial "2024-03-15"
}

# ============================================================================
# Integration Tests
# ============================================================================

@test "list.sh works with multiple options combined" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
echo "https://www.twitch.tv/videos/123"
exit 0
'
  
  run "${SCRIPTS_DIR}/list.sh" "testchannel" --urls-only --limit 5
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--playlist-end 5"
  assert_output --partial "--print url"
}
