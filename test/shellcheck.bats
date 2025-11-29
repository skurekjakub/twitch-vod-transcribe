#!/usr/bin/env bats

# ShellCheck linting tests for all shell scripts
# Runs shellcheck on vod CLI and all scripts
# Uses severity level "warning" to ignore info/style hints

setup() {
  load 'test_helper/common-setup'
  _common_setup
}

teardown() {
  _common_teardown
}

# ============================================================================
# ShellCheck Availability
# ============================================================================

@test "shellcheck is installed" {
  run command -v shellcheck
  assert_success
}

# ============================================================================
# Main CLI
# ============================================================================

@test "shellcheck: vod entrypoint passes" {
  run shellcheck -x -s bash "${PROJECT_ROOT}/vod"
  assert_success
}

# ============================================================================
# Scripts Directory
# ============================================================================

@test "shellcheck: scripts/download.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/download.sh"
  assert_success
}

@test "shellcheck: scripts/transcribe.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/transcribe.sh"
  assert_success
}

@test "shellcheck: scripts/youtube.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/youtube.sh"
  assert_success
}

@test "shellcheck: scripts/batch-download.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/batch-download.sh"
  assert_success
}

@test "shellcheck: scripts/batch-transcribe.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/batch-transcribe.sh"
  assert_success
}

@test "shellcheck: scripts/list.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/list.sh"
  assert_success
}

@test "shellcheck: scripts/list-youtube.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/list-youtube.sh"
  assert_success
}

@test "shellcheck: scripts/list-playlist.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/list-playlist.sh"
  assert_success
}

@test "shellcheck: scripts/split.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/split.sh"
  assert_success
}

@test "shellcheck: scripts/twitchdownloader.sh passes" {
  run shellcheck -x -s bash "${SCRIPTS_DIR}/twitchdownloader.sh"
  assert_success
}

# ============================================================================
# Lib Directory
# ============================================================================

@test "shellcheck: lib/extract-audio.sh passes" {
  run shellcheck -x -s bash "${LIB_DIR}/extract-audio.sh"
  assert_success
}

@test "shellcheck: lib/transcribe-audio.sh passes" {
  run shellcheck -x -s bash "${LIB_DIR}/transcribe-audio.sh"
  assert_success
}

# ============================================================================
# Test Helper
# ============================================================================

@test "shellcheck: test/test_helper/common-setup.bash passes" {
  run shellcheck -x -s bash "${PROJECT_ROOT}/test/test_helper/common-setup.bash"
  assert_success
}

# ============================================================================
# Test Runner
# ============================================================================

@test "shellcheck: test/run_tests.sh passes" {
  run shellcheck -x -s bash "${PROJECT_ROOT}/test/run_tests.sh"
  assert_success
}

# ============================================================================
# All Scripts Combined (warning level only)
# ============================================================================

@test "shellcheck: all shell scripts pass (warning level)" {
  local failed=0
  local failed_files=""
  
  # Check main CLI
  if ! shellcheck -x -s bash "${PROJECT_ROOT}/vod" 2>/dev/null; then
    failed=$((failed + 1))
    failed_files="${failed_files}\n  - vod"
  fi
  
  # Check all scripts
  for script in "${SCRIPTS_DIR}"/*.sh; do
    if ! shellcheck -x -s bash "$script" 2>/dev/null; then
      failed=$((failed + 1))
      failed_files="${failed_files}\n  - $(basename "$script")"
    fi
  done
  
  # Check lib scripts
  for script in "${LIB_DIR}"/*.sh; do
    if ! shellcheck -x -s bash "$script" 2>/dev/null; then
      failed=$((failed + 1))
      failed_files="${failed_files}\n  - lib/$(basename "$script")"
    fi
  done
  
  if [[ $failed -gt 0 ]]; then
    echo "ShellCheck found issues in $failed files:${failed_files}"
    return 1
  fi
}
