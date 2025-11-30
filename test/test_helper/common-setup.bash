#!/bin/bash

# Common setup for all tests
# Loads bats helper libraries and sets up common variables

# Get the root directory of the project
_common_setup() {
  # Root directory (one level up from test directory)
  # BATS_TEST_DIRNAME is the directory containing the test file
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  
  # Test directory (for loading helpers)
  TEST_DIR="${BATS_TEST_DIRNAME}"
  
  # Load bats helpers (relative to test directory)
  load "${TEST_DIR}/bats-support/load"
  load "${TEST_DIR}/bats-assert/load"
  load "${TEST_DIR}/bats-file/load"
  
  # Path to main CLI
  VOD="${PROJECT_ROOT}/vod"
  
  # Path to scripts directory
  SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
  
  # Path to lib directory  
  LIB_DIR="${PROJECT_ROOT}/lib"
  
  # Create temp directory for test artifacts
  TEST_TEMP_DIR="$(mktemp -d)"
  
  # Create mock bin directory and add to PATH
  MOCK_BIN_DIR="${TEST_TEMP_DIR}/mock_bin"
  mkdir -p "$MOCK_BIN_DIR"
  PATH="${MOCK_BIN_DIR}:${PATH}"
  
  # Set VOD_ROOT_DIR so scripts use test temp directory instead of project root
  # This allows tests to create files that scripts will find
  VOD_ROOT_DIR="${TEST_TEMP_DIR}"
  
  # Set lib script paths to use mocks from MOCK_BIN_DIR
  EXTRACT_AUDIO_SCRIPT="${MOCK_BIN_DIR}/extract-audio.sh"
  TRANSCRIBE_AUDIO_SCRIPT="${MOCK_BIN_DIR}/transcribe-audio.sh"
  
  # Create standard directory structure in test temp dir
  mkdir -p "${TEST_TEMP_DIR}/logs"
  mkdir -p "${TEST_TEMP_DIR}/vods"
  mkdir -p "${TEST_TEMP_DIR}/videos"
  mkdir -p "${TEST_TEMP_DIR}/transcripts"
  mkdir -p "${TEST_TEMP_DIR}/lib"
  
  # Export for subprocesses
  export PROJECT_ROOT VOD SCRIPTS_DIR LIB_DIR TEST_TEMP_DIR MOCK_BIN_DIR VOD_ROOT_DIR
  export EXTRACT_AUDIO_SCRIPT TRANSCRIBE_AUDIO_SCRIPT
}

# Clean up temp directory after each test
_common_teardown() {
  if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Create a mock command that records its invocations
# Usage: create_mock <command_name> [exit_code] [stdout_output]
create_mock() {
  local cmd_name="$1"
  local exit_code="${2:-0}"
  local stdout="${3:-}"
  local mock_script="${MOCK_BIN_DIR}/${cmd_name}"
  
  cat > "$mock_script" << EOF
#!/bin/bash
# Mock for: ${cmd_name}
# Record invocation
echo "\$0 \$*" >> "${TEST_TEMP_DIR}/${cmd_name}.calls"
# Output if specified
if [[ -n "${stdout}" ]]; then
  echo "${stdout}"
fi
exit ${exit_code}
EOF
  chmod +x "$mock_script"
}

# Create a mock that outputs from a file
# Usage: create_mock_with_file <command_name> <output_file> [exit_code]
create_mock_with_file() {
  local cmd_name="$1"
  local output_file="$2"
  local exit_code="${3:-0}"
  local mock_script="${MOCK_BIN_DIR}/${cmd_name}"
  
  cat > "$mock_script" << EOF
#!/bin/bash
# Mock for: ${cmd_name}
echo "\$0 \$*" >> "${TEST_TEMP_DIR}/${cmd_name}.calls"
cat "${output_file}"
exit ${exit_code}
EOF
  chmod +x "$mock_script"
}

# Create a mock that behaves differently based on arguments
# Usage: create_conditional_mock <command_name> <script_body>
create_conditional_mock() {
  local cmd_name="$1"
  local script_body="$2"
  local mock_script="${MOCK_BIN_DIR}/${cmd_name}"
  
  cat > "$mock_script" << EOF
#!/bin/bash
# Mock for: ${cmd_name}
echo "\$0 \$*" >> "${TEST_TEMP_DIR}/${cmd_name}.calls"
${script_body}
EOF
  chmod +x "$mock_script"
}

# Check if a mock was called
# Usage: assert_mock_called <command_name>
assert_mock_called() {
  local cmd_name="$1"
  assert_file_exists "${TEST_TEMP_DIR}/${cmd_name}.calls"
}

# Check if a mock was called with specific arguments
# Usage: assert_mock_called_with <command_name> <expected_args_pattern>
assert_mock_called_with() {
  local cmd_name="$1"
  local pattern="$2"
  assert_file_exists "${TEST_TEMP_DIR}/${cmd_name}.calls"
  run grep -E -- "$pattern" "${TEST_TEMP_DIR}/${cmd_name}.calls"
  assert_success
}

# Check mock was NOT called
# Usage: assert_mock_not_called <command_name>
assert_mock_not_called() {
  local cmd_name="$1"
  assert_file_not_exists "${TEST_TEMP_DIR}/${cmd_name}.calls"
}

# Get number of times a mock was called
# Usage: get_mock_call_count <command_name>
get_mock_call_count() {
  local cmd_name="$1"
  if [[ -f "${TEST_TEMP_DIR}/${cmd_name}.calls" ]]; then
    wc -l < "${TEST_TEMP_DIR}/${cmd_name}.calls"
  else
    echo "0"
  fi
}

# Create a test URL file
# Usage: create_url_file <filename> <content>
create_url_file() {
  local filename="$1"
  shift
  local filepath="${TEST_TEMP_DIR}/${filename}"
  printf '%s\n' "$@" > "$filepath"
  echo "$filepath"
}

# Create a test video file (just a placeholder)
# Usage: create_test_video <filename> [size_in_bytes]
create_test_video() {
  local filename="$1"
  local size="${2:-1024}"
  local filepath="${TEST_TEMP_DIR}/${filename}"
  dd if=/dev/zero of="$filepath" bs=1 count="$size" 2>/dev/null
  echo "$filepath"
}

# Sample yt-dlp JSON metadata for testing
sample_ytdlp_json() {
  local title="${1:-Test Video Title}"
  local channel="${2:-TestChannel}"
  local upload_date="${3:-20251129}"
  
  cat << EOF
{"title": "${title}", "uploader": "${channel}", "upload_date": "${upload_date}", "duration": 3600, "duration_string": "1:00:00", "webpage_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", "id": "dQw4w9WgXcQ"}
EOF
}

# Sample yt-dlp JSON with chapters
sample_ytdlp_json_with_chapters() {
  local title="${1:-Test Video Title}"
  local channel="${2:-TestChannel}"
  local upload_date="${3:-20251129}"
  
  cat << EOF
{"title": "${title}", "uploader": "${channel}", "upload_date": "${upload_date}", "duration": 7200, "chapters": [{"title": "Chapter 1", "start_time": 0}, {"title": "Chapter 2", "start_time": 1800}, {"title": "Chapter 3", "start_time": 3600}], "webpage_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", "id": "dQw4w9WgXcQ"}
EOF
}
