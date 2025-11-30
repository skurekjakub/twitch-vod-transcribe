#!/usr/bin/env bats

# Tests for scripts/list-playlist.sh
# Covers: YouTube playlist URL building, output formats, options

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

@test "list-playlist.sh --help shows help" {
  run "${SCRIPTS_DIR}/list-playlist.sh" --help
  assert_success
  assert_output --partial "List YouTube Playlist Videos"
  assert_output --partial "Usage: vod list-playlist"
  assert_output --partial "--urls-only"
  assert_output --partial "--limit"
  assert_output --partial "--output"
}

@test "list-playlist.sh -h shows help" {
  run "${SCRIPTS_DIR}/list-playlist.sh" -h
  assert_success
  assert_output --partial "List YouTube Playlist Videos"
}

@test "list-playlist.sh with no arguments shows help" {
  run "${SCRIPTS_DIR}/list-playlist.sh"
  assert_success
  assert_output --partial "Usage: vod list-playlist"
}

# ============================================================================
# Playlist URL Building Tests
# ============================================================================

@test "list-playlist.sh converts PL ID to full URL" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "youtube.com/playlist?list=PLtest123"
}

@test "list-playlist.sh handles full playlist URL" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "https://www.youtube.com/playlist?list=PLtest123" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "youtube.com/playlist?list=PLtest123"
}

@test "list-playlist.sh handles playlist ID without PL prefix" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "randomid123" --urls-only
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "youtube.com/playlist?list=randomid123"
}

# ============================================================================
# Option Parsing Tests
# ============================================================================

@test "list-playlist.sh accepts --urls-only flag" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
  echo "https://www.youtube.com/watch?v=test2"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --urls-only
  
  assert_success
  assert_output --partial "https://www.youtube.com/watch"
}

@test "list-playlist.sh accepts --limit option" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --limit 10
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--playlist-end 10"
}

@test "list-playlist.sh accepts --json flag" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--dump-json"* ]]; then
  echo "{\"title\": \"Test Video\"}"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --json
  
  assert_success
}

@test "list-playlist.sh accepts -o flag (output to file)" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"playlist_title"* ]]; then
  echo "My Test Playlist"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" -o
  
  assert_success
  assert_output --partial "Playlist:"
  assert_output --partial "Output file: urls-"
}

@test "list-playlist.sh accepts --output flag" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"playlist_title"* ]]; then
  echo "TestPlaylist"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --output
  
  assert_success
  assert_output --partial "Output file:"
}

@test "list-playlist.sh rejects unknown options" {
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --unknown
  
  assert_failure
  assert_output --partial "Unknown option"
}

# ============================================================================
# Output File Tests
# ============================================================================

@test "list-playlist.sh -o creates file with playlist name" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"playlist_title"* ]]; then
  echo "TestPlaylist"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" -o
  
  # Check output mentions the file
  assert_output --partial "urls-testplaylist"
}

@test "list-playlist.sh -o sanitizes playlist name for filename" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"playlist_title"* ]]; then
  echo "My Playlist With Spaces & Symbols!"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" -o
  
  # Should sanitize name (lowercase, remove special chars)
  assert_output --partial "Output file: urls-"
  # Verify no special chars in filename
  refute_output --partial "urls-My Playlist"
}

@test "list-playlist.sh -o uses playlist ID as fallback" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"playlist_title"* ]]; then
  echo "NA"  # Fallback value
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123abc" -o
  
  # Should fallback to playlist ID
  assert_output --partial "urls-"
}

@test "list-playlist.sh -o reports URL count" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"playlist_title"* ]]; then
  echo "TestPlaylist"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
  echo "https://www.youtube.com/watch?v=test2"
  echo "https://www.youtube.com/watch?v=test3"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" -o
  
  assert_output --partial "Saved 3 URLs"
}

# ============================================================================
# Output Format Tests
# ============================================================================

@test "list-playlist.sh human-readable uses flat-playlist" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123"
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--flat-playlist"
}

@test "list-playlist.sh human-readable shows index, duration, title, URL" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123"
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  # Check for print format with playlist_index, duration, title, URL
  assert_output --partial "playlist_index"
  assert_output --partial "duration_string"
  assert_output --partial "title"
  assert_output --partial "webpage_url"
}

@test "list-playlist.sh shows playlist URL in output" {
  create_mock "yt-dlp" 0 ""
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123"
  
  assert_output --partial "Fetching videos from playlist"
}

# ============================================================================
# URL Format Tests
# ============================================================================

@test "list-playlist.sh handles various YouTube playlist URL formats" {
  # Test with parameters after list
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "https://www.youtube.com/playlist?list=PLtest123&index=1" --urls-only
  
  # Should pass the URL to yt-dlp
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "PLtest123"
}

# ============================================================================
# Integration Tests
# ============================================================================

@test "list-playlist.sh works with multiple options" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
echo "https://www.youtube.com/watch?v=test1"
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --urls-only --limit 5
  
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--playlist-end 5"
  assert_output --partial "--print url"
}

@test "list-playlist.sh -o implies --urls-only" {
  create_conditional_mock "yt-dlp" '
echo "yt-dlp args: $*" >> "'"${TEST_TEMP_DIR}"'/yt-dlp.log"
if [[ "$*" == *"playlist_title"* ]]; then
  echo "TestPlaylist"
else
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" -o
  
  # Should have used --print url even without explicit --urls-only
  run cat "${TEST_TEMP_DIR}/yt-dlp.log"
  assert_output --partial "--print url"
}

# ============================================================================
# Prefix Option Tests
# ============================================================================

@test "list-playlist.sh --help shows --prefix option" {
  run "${SCRIPTS_DIR}/list-playlist.sh" --help
  assert_success
  assert_output --partial "--prefix"
  assert_output --partial "Add prefix to all URLs"
}

@test "list-playlist.sh accepts --prefix option" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
  echo "https://www.youtube.com/watch?v=test2"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --urls-only --prefix "myprefix"
  
  assert_success
  assert_output --partial "https://www.youtube.com/watch?v=test1 myprefix"
  assert_output --partial "https://www.youtube.com/watch?v=test2 myprefix"
}

@test "list-playlist.sh --prefix adds prefix to all URLs in stdout" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=video1"
  echo "https://www.youtube.com/watch?v=video2"
  echo "https://www.youtube.com/watch?v=video3"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --urls-only --prefix "swampletics"
  
  assert_success
  # Each line should have the prefix appended
  assert_line --index 0 "https://www.youtube.com/watch?v=video1 swampletics"
  assert_line --index 1 "https://www.youtube.com/watch?v=video2 swampletics"
  assert_line --index 2 "https://www.youtube.com/watch?v=video3 swampletics"
}

@test "list-playlist.sh -o --prefix saves URLs with prefix to file" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"playlist_title"* ]]; then
  echo "TestPlaylist"
elif [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
  echo "https://www.youtube.com/watch?v=test2"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" -o --prefix "myprefix"
  
  assert_success
  assert_output --partial "Saved 2 URLs"
  
  # Check the file contents
  run cat "urls-testplaylist"
  assert_line --index 0 "https://www.youtube.com/watch?v=test1 myprefix"
  assert_line --index 1 "https://www.youtube.com/watch?v=test2 myprefix"
}

@test "list-playlist.sh without --prefix outputs URLs without suffix" {
  create_conditional_mock "yt-dlp" '
if [[ "$*" == *"--print url"* ]]; then
  echo "https://www.youtube.com/watch?v=test1"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/list-playlist.sh" "PLtest123" --urls-only
  
  assert_success
  assert_output "https://www.youtube.com/watch?v=test1"
  refute_output --partial " "
}
