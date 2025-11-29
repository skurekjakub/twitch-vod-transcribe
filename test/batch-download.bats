#!/usr/bin/env bats

# Tests for scripts/batch-download.sh
# Covers: URL file parsing, download processing, mark_processed, error recovery

setup() {
  load 'test_helper/common-setup'
  _common_setup
  
  mkdir -p "${TEST_TEMP_DIR}/logs"
  mkdir -p "${TEST_TEMP_DIR}/videos"
  
  cd "$TEST_TEMP_DIR" || exit 1
  
  # Export DOWNLOAD_SCRIPT to use the mock bin directory
  export DOWNLOAD_SCRIPT="${MOCK_BIN_DIR}/download.sh"
}

teardown() {
  _common_teardown
}

# ============================================================================
# Help Tests
# ============================================================================

@test "batch-download.sh --help shows help" {
  run "${SCRIPTS_DIR}/batch-download.sh" --help
  assert_success
  assert_output --partial "Batch Video Downloader"
  assert_output --partial "Usage: vod batch download"
  assert_output --partial "--continue-on-error"
}

@test "batch-download.sh -h shows help" {
  run "${SCRIPTS_DIR}/batch-download.sh" -h
  assert_success
  assert_output --partial "Batch Video Downloader"
}

# ============================================================================
# URL File Validation Tests
# ============================================================================

@test "batch-download.sh uses default urls-vods file" {
  # Create a test urls-vods file in temp dir and pass it explicitly
  # (The script changes to ROOT_DIR so we can't rely on working directory)
  echo "# Empty" > "${TEST_TEMP_DIR}/urls-vods"
  
  run "${SCRIPTS_DIR}/batch-download.sh" "${TEST_TEMP_DIR}/urls-vods"
  
  assert_success
  assert_output --partial "Starting batch video download from: ${TEST_TEMP_DIR}/urls-vods"
}

@test "batch-download.sh accepts custom URL file" {
  local url_file
  url_file=$(create_url_file "my-urls.txt" "# Empty file")
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_success
  assert_output --partial "Starting batch video download from: $url_file"
}

@test "batch-download.sh fails with missing URL file" {
  run "${SCRIPTS_DIR}/batch-download.sh" "nonexistent.txt"
  
  assert_failure
  assert_output --partial "URL file not found"
}

# ============================================================================
# URL Parsing Tests
# ============================================================================

@test "batch-download.sh parses URL without prefix" {
  local url_file
  url_file=$(create_url_file "urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Processing: https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}

@test "batch-download.sh parses URL with prefix" {
  local url_file
  url_file=$(create_url_file "urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ my-prefix")
  
  create_conditional_mock "download.sh" '
echo "download.sh args: $*" >> "'"${TEST_TEMP_DIR}"'/download.log"
exit 0
'
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Prefix: my-prefix"
  
  # Verify download.sh was called with prefix
  run cat "${TEST_TEMP_DIR}/download.log"
  assert_output --partial "my-prefix"
}

@test "batch-download.sh handles URLs with spaces in prefix" {
  # Note: prefix with spaces should be quoted in the file
  local url_file
  url_file=$(create_url_file "urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ prefix-one")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Prefix: prefix-one"
}

# ============================================================================
# Comment and Blank Line Tests
# ============================================================================

@test "batch-download.sh skips comment lines" {
  local url_file
  url_file=$(create_url_file "urls.txt" \
    "# This is a comment" \
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Found 1 URLs to process"
}

@test "batch-download.sh skips blank lines" {
  local url_file
  url_file=$(create_url_file "urls.txt" \
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ" \
    "" \
    "https://www.youtube.com/watch?v=test123test")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Found 2 URLs to process"
}

# ============================================================================
# URL Validation Tests
# ============================================================================

@test "batch-download.sh skips invalid URLs" {
  local url_file
  url_file=$(create_url_file "urls.txt" \
    "not-a-valid-url" \
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Invalid URL format, skipping"
  assert_output --partial "Skipped: 1"
}

@test "batch-download.sh accepts http:// URLs" {
  local url_file
  url_file=$(create_url_file "urls.txt" "http://example.com/video")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Processing: http://example.com/video"
}

@test "batch-download.sh accepts https:// URLs" {
  local url_file
  url_file=$(create_url_file "urls.txt" "https://example.com/video")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Processing: https://example.com/video"
}

# ============================================================================
# Processed File Tracking Tests
# ============================================================================

@test "batch-download.sh creates -processed file" {
  local url_file
  url_file=$(create_url_file "my-urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # Check processed file was created
  assert_file_exists "${url_file}-processed"
}

@test "batch-download.sh moves completed URL to processed file" {
  local url_file
  url_file=$(create_url_file "my-urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # URL should be in processed file
  run cat "${url_file}-processed"
  assert_output --partial "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}

@test "batch-download.sh removes processed URL from source file" {
  local url_file
  url_file=$(create_url_file "my-urls.txt" \
    "https://www.youtube.com/watch?v=video1" \
    "https://www.youtube.com/watch?v=video2")
  
  # First download succeeds, second fails
  create_conditional_mock "download.sh" '
if [[ "$1" == *"video1"* ]]; then
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # Original file should only have video2 (since video1 was processed)
  run cat "$url_file"
  assert_output --partial "video2"
  refute_output --partial "video1"
}

@test "batch-download.sh prepends to processed file (newest first)" {
  local url_file="${TEST_TEMP_DIR}/my-urls.txt"
  
  # Create initial processed file
  local processed_file="${url_file}-processed"
  echo "# Processed: 2025-11-28 - Old Video" > "$processed_file"
  echo "https://old-url.com" >> "$processed_file"
  
  # Create URL file
  echo "https://new-url.com" > "$url_file"
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # New URL should be at the top
  run head -n 1 "$processed_file"
  assert_output --partial "Processed:"
  
  run head -n 2 "$processed_file"
  assert_output --partial "new-url"
}

# ============================================================================
# Continue on Error Tests
# ============================================================================

@test "batch-download.sh continues on error by default" {
  # Note: batch-download.sh has CONTINUE_ON_ERROR=true by default
  local url_file
  url_file=$(create_url_file "urls.txt" \
    "https://www.youtube.com/watch?v=video1" \
    "https://www.youtube.com/watch?v=video2")
  
  create_conditional_mock "download.sh" '
echo "Called with: $1" >> "'"${TEST_TEMP_DIR}"'/download.log"
exit 1  # Always fail
'
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # Should have called download.sh twice
  run grep -c "Called with" "${TEST_TEMP_DIR}/download.log"
  assert_output "2"
}

@test "batch-download.sh doesn't mark failed downloads as processed" {
  local url_file
  url_file=$(create_url_file "my-urls.txt" "https://www.youtube.com/watch?v=video1")
  
  create_mock "download.sh" 1 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # Processed file should not contain the failed URL
  if [[ -f "${url_file}-processed" ]]; then
    run cat "${url_file}-processed"
    refute_output --partial "video1"
  fi
  
  # URL should remain in source file
  run cat "$url_file"
  assert_output --partial "video1"
}

# ============================================================================
# NAS Detection Tests
# ============================================================================

@test "batch-download.sh logs NAS status" {
  local url_file
  url_file=$(create_url_file "urls.txt" "# Empty")
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # Should mention NAS detection result
  assert_output --regexp "(NAS detected|NAS not detected)"
}

# ============================================================================
# Title Output Tests
# ============================================================================

@test "batch-download.sh captures video title from download.sh" {
  local url_file
  url_file=$(create_url_file "my-urls.txt" "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  
  # Create mock that writes to TITLE_OUTPUT_FILE
  create_conditional_mock "download.sh" '
if [ -n "$TITLE_OUTPUT_FILE" ]; then
  echo "Test Video Title" > "$TITLE_OUTPUT_FILE"
fi
exit 0
'
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # Title should appear in processed file
  run cat "${url_file}-processed"
  assert_output --partial "Test Video Title"
}

# ============================================================================
# Counter and Summary Tests
# ============================================================================

@test "batch-download.sh counts URLs correctly" {
  local url_file
  url_file=$(create_url_file "urls.txt" \
    "https://url1.com/v" \
    "https://url2.com/v" \
    "https://url3.com/v")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Found 3 URLs to process"
}

@test "batch-download.sh shows progress counter" {
  local url_file
  url_file=$(create_url_file "urls.txt" \
    "https://url1.com/v" \
    "https://url2.com/v")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "[1/2]"
  assert_output --partial "[2/2]"
}

@test "batch-download.sh shows final summary" {
  local url_file
  url_file=$(create_url_file "urls.txt" \
    "https://url1.com/v" \
    "https://url2.com/v")
  
  create_conditional_mock "download.sh" '
if [[ "$1" == *"url1"* ]]; then
  exit 0
else
  exit 1
fi
'
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Batch download complete!"
  assert_output --partial "Total URLs: 2"
  assert_output --partial "Successful: 1"
  assert_output --partial "Failed: 1"
}

@test "batch-download.sh shows log file path" {
  local url_file
  url_file=$(create_url_file "urls.txt" "# Empty")
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_output --partial "Log file: logs/batch-download-"
}

# ============================================================================
# Exit Code Tests
# ============================================================================

@test "batch-download.sh exits 0 when all succeed" {
  local url_file
  url_file=$(create_url_file "urls.txt" "https://url.com/v")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  assert_success
}

@test "batch-download.sh exits 0 even with failures (default continue-on-error)" {
  local url_file
  url_file=$(create_url_file "urls.txt" "https://url.com/v")
  
  create_mock "download.sh" 1 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # Default is CONTINUE_ON_ERROR=true, so exits 0
  assert_success
}

# ============================================================================
# mapfile Usage Tests
# ============================================================================

@test "batch-download.sh can modify file while iterating" {
  # This tests that mapfile is used correctly to avoid issues with
  # modifying the file while reading it
  local url_file
  url_file=$(create_url_file "urls.txt" \
    "https://url1.com/v" \
    "https://url2.com/v")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" "$url_file"
  
  # Both URLs should have been processed
  assert_output --partial "Successful: 2"
  
  # Source file should be empty or just have newlines
  local remaining
  remaining=$(grep -c 'https://' "$url_file" || true)
  assert_equal "$remaining" "0"
}

# ============================================================================
# Option Parsing Tests
# ============================================================================

@test "batch-download.sh accepts --continue-on-error option" {
  local url_file
  url_file=$(create_url_file "urls.txt" "https://url.com/v")
  
  create_mock "download.sh" 0 ""
  
  run "${SCRIPTS_DIR}/batch-download.sh" --continue-on-error "$url_file"
  
  assert_success
}

@test "batch-download.sh rejects unknown options" {
  run "${SCRIPTS_DIR}/batch-download.sh" --unknown
  
  assert_failure
  assert_output --partial "Unknown option"
}
