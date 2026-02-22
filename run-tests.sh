#!/usr/bin/env bash
# run-tests.sh — install bats helpers (if needed) and run the full test suite
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/test"

# Install bats-core and helpers if not already present
install_if_missing() {
  local dir="$1" repo="$2"
  if [[ ! -d "$dir" ]]; then
    echo "→ Cloning ${repo##*/}..."
    git clone --depth 1 "https://github.com/bats-core/${repo}.git" "$dir"
  fi
}

install_if_missing "${TEST_DIR}/bats-core"    bats-core
install_if_missing "${TEST_DIR}/bats-support" bats-support
install_if_missing "${TEST_DIR}/bats-assert"  bats-assert
install_if_missing "${TEST_DIR}/bats-file"    bats-file

# Make all scripts executable
chmod +x "${SCRIPT_DIR}/vod" "${SCRIPT_DIR}/scripts"/*.sh

# Run tests
echo ""
echo "Running tests in ${TEST_DIR}..."
echo ""
exec "${TEST_DIR}/bats-core/bin/bats" --timing "${TEST_DIR}"/*.bats "$@"
