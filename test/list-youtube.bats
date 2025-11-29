#!/usr/bin/env bats

# Tests for scripts/list-youtube.sh
# Covers: YouTube channel URL building, output formats, shorts filtering

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

@test "list-youtube.sh --help shows help" {
  run "${SCRIPTS_DIR}/list-youtube.sh" --help
  assert_success
  assert_output --partial "List YouTube Channel Videos"
  assert_output --partial "Usage: vod list-youtube"
  assert_output --partial "--urls-only"
  assert_output --partial "--limit"
  assert_output --partial "--output"
}

@test "list-youtube.sh -h shows help" {
  run "${SCRIPTS_DIR}/list-youtube.sh" -h
  assert_success
  assert_output --partial "List YouTube Channel Videos"
}

@test "list-youtube.sh with no arguments shows help" {
  run "${SCRIPTS_DIR}/list-youtube.sh"
  assert_success
  assert_output --partial "Usage: vod list-youtube"
}

# ============================================================================
# Channel URL Building Tests
# ============================================================================

@test "list-youtube.sh converts @ handle to full URL" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@MrBeast" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "youtube.com/@MrBeast/videos"
}

@test "list-youtube.sh handles full YouTube URL" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "https://www.youtube.com/@MrBeast" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "youtube.com/@MrBeast/videos"
}

@test "list-youtube.sh removes /videos suffix and re-adds it" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "https://www.youtube.com/@Test/videos" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  # Should not have /videos/videos
  refute_output --partial "/videos/videos"
}

@test "list-youtube.sh removes /streams suffix" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "https://www.youtube.com/@Test/streams" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "/videos"
  refute_output --partial "/streams"
}

@test "list-youtube.sh handles channel name without @" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "testchannel" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "youtube.com/testchannel/videos"
}

# ============================================================================
# Shorts and Live Filtering Tests
# ============================================================================

@test "list-youtube.sh filters out shorts (duration > 60)" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "duration>60"
}

@test "list-youtube.sh filters out live streams" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "!is_live"
}

@test "list-youtube.sh mentions filtering in human-readable output" {
  create_mock "yt-dlp" 0 ""
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test"
  
  assert_output --partial "Excluding: Shorts"
  assert_output --partial "Live streams"
}

# ============================================================================
# Option Parsing Tests
# ============================================================================

@test "list-youtube.sh accepts --urls-only flag" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
  echo "https://www.youtube.com/watch?v=test2"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test" --urls-only
  
  assert_success
  assert_output --partial "https://www.youtube.com/watch"
}

@test "list-youtube.sh accepts --limit option" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test" --limit 20
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--playlist-end 20"
}

@test "list-youtube.sh accepts --json flag" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  echo "{\"title\": \"Test Video\"}"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test" --json
  
  assert_success
}

@test "list-youtube.sh accepts -o flag (output to file)" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--playlist-end 1"* ]]; then
  echo "TestChannel"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@TestChannel" -o
  
  assert_success
  assert_output --partial "Channel:"
  assert_output --partial "Output file: urls-"
}

@test "list-youtube.sh accepts --output flag" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--print"* ]] && [[ "$*" == *"channel"* ]]; then
  echo "TestChannel"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@TestChannel" --output
  
  assert_success
  assert_output --partial "Output file:"
}

@test "list-youtube.sh rejects unknown options" {
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test" --unknown
  
  assert_failure
  assert_output --partial "Unknown option"
}

# ============================================================================
# Output File Tests
# ============================================================================

@test "list-youtube.sh -o creates file with channel name" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"channel"* ]]; then
  echo "MyChannel"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@MyChannel" -o
  
  # Script creates file in VOD_ROOT_DIR (which is TEST_TEMP_DIR)
  assert_file_exists "${VOD_ROOT_DIR}/urls-MyChannel"
}

@test "list-youtube.sh -o sanitizes channel name for filename" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"channel"* ]]; then
  echo "Test Channel With Spaces!"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@Test" -o
  
  # Should sanitize name (remove special chars)
  assert_output --partial "Output file: urls-"
}

@test "list-youtube.sh -o reports URL count" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"channel"* ]]; then
  echo "TestChannel"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
  echo "https://www.youtube.com/watch?v=test2"
  echo "https://www.youtube.com/watch?v=test3"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@TestChannel" -o
  
  assert_output --partial "Saved 3 URLs"
}

# ============================================================================
# Output Format Tests
# ============================================================================

@test "list-youtube.sh human-readable uses flat-playlist" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test"
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--flat-playlist"
}

@test "list-youtube.sh human-readable shows date, duration, title, URL" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test"
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  # Check for print format with date, duration, title, URL
  assert_output --partial "upload_date"
  assert_output --partial "duration_string"
  assert_output --partial "title"
  assert_output --partial "webpage_url"
}

# ============================================================================
# Channel Name Extraction Tests
# ============================================================================

@test "list-youtube.sh extracts channel name from @ handle for -o" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"channel"* ]]; then
  echo ""  # Empty - should fallback
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://test.com"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@FallbackName" -o
  
  # Should use fallback from input
  assert_output --partial "FallbackName"
}

# ============================================================================
# Integration Tests
# ============================================================================

@test "list-youtube.sh works with multiple options" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
echo "https://www.youtube.com/watch?v=test1"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-youtube.sh" "@test" --urls-only --limit 10
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--playlist-end 10"
  assert_output --partial "--print url"
}
