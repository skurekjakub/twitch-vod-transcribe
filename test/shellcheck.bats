#!/usr/bin/env bats

# ShellCheck linting tests for all shell scripts
# Dynamically discovers and tests all shell scripts in the project
# Configuration in .shellcheckrc at project root

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
# All Shell Scripts (Dynamic Discovery)
# ============================================================================

@test "shellcheck: all scripts pass" {
  local failed=0
  local failed_files=""
  local checked=0
  
  # Check main CLI entrypoint
  if [[ -f "${PROJECT_ROOT}/vod" ]]; then
    checked=$((checked + 1))
    if ! shellcheck "${PROJECT_ROOT}/vod" 2>&1; then
      failed=$((failed + 1))
      failed_files="${failed_files}\n  - vod"
    fi
  fi
  
  # Check scripts directory
  for script in "${SCRIPTS_DIR}"/*.sh; do
    [[ -f "$script" ]] || continue
    checked=$((checked + 1))
    if ! shellcheck "$script" 2>&1; then
      failed=$((failed + 1))
      failed_files="${failed_files}\n  - scripts/$(basename "$script")"
    fi
  done
  
  # Check lib directory (recursive)
  while IFS= read -r -d '' script; do
    checked=$((checked + 1))
    if ! shellcheck "$script" 2>&1; then
      failed=$((failed + 1))
      failed_files="${failed_files}\n  - lib/$(basename "$script")"
    fi
  done < <(find "${LIB_DIR}" -type f -name "*.sh" -print0 2>/dev/null)
  
  # Check test helpers (not .bats files)
  while IFS= read -r -d '' script; do
    [[ "$script" == */bats-*/* ]] && continue
    checked=$((checked + 1))
    local rel_path="${script#"${PROJECT_ROOT}/"}"
    if ! shellcheck "$script" 2>&1; then
      failed=$((failed + 1))
      failed_files="${failed_files}\n  - ${rel_path}"
    fi
  done < <(find "${PROJECT_ROOT}/test" -type f \( -name "*.sh" -o -name "*.bash" \) -print0 2>/dev/null)
  
  echo "Checked ${checked} shell scripts"
  
  if [[ $failed -gt 0 ]]; then
    echo -e "ShellCheck found issues in ${failed} files:${failed_files}"
    return 1
  fi
}
