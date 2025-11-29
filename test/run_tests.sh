#!/bin/bash
# Test runner script for VOD CLI tests
# Usage: ./test/run_tests.sh [test_file.bats] [--verbose] [--filter pattern]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_BIN="${SCRIPT_DIR}/bats-core/bin/bats"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
VERBOSE=""
FILTER=""
SPECIFIC_TEST=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE="--verbose-run"
      shift
      ;;
    -f|--filter)
      FILTER="--filter $2"
      shift 2
      ;;
    -h|--help)
      cat << 'EOF'
VOD CLI Test Runner

Usage: ./test/run_tests.sh [options] [test_file.bats]

Options:
  -v, --verbose      Show verbose output
  -f, --filter PAT   Only run tests matching pattern
  -h, --help         Show this help

Examples:
  ./test/run_tests.sh                    # Run all tests
  ./test/run_tests.sh vod.bats           # Run specific test file
  ./test/run_tests.sh -f "help"          # Run tests matching "help"
  ./test/run_tests.sh -v download.bats   # Verbose output for download tests
EOF
      exit 0
      ;;
    *.bats)
      SPECIFIC_TEST="$1"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Ensure bats-core and helper libraries are installed
ensure_bats_dependencies() {
  local missing=0
  
  # Check and install bats-core
  if [[ ! -d "${SCRIPT_DIR}/bats-core" ]]; then
    echo -e "${YELLOW}Installing bats-core...${NC}"
    git clone --depth 1 https://github.com/bats-core/bats-core.git "${SCRIPT_DIR}/bats-core"
    missing=1
  fi
  
  # Check and install helper libraries
  for lib in bats-support bats-assert bats-file; do
    if [[ ! -d "${SCRIPT_DIR}/${lib}" ]]; then
      echo -e "${YELLOW}Installing ${lib}...${NC}"
      git clone --depth 1 "https://github.com/bats-core/${lib}.git" "${SCRIPT_DIR}/${lib}"
      missing=1
    fi
  done
  
  if [[ $missing -eq 1 ]]; then
    echo -e "${GREEN}Bats dependencies installed successfully${NC}"
    echo ""
  fi
}

# Check for shellcheck
check_shellcheck() {
  if ! command -v shellcheck &>/dev/null; then
    echo -e "${YELLOW}Warning: shellcheck not installed. Shellcheck tests will be skipped.${NC}"
    echo -e "${YELLOW}Install with: apt-get install shellcheck${NC}"
    return 1
  fi
  return 0
}

# Ensure dependencies are installed
ensure_bats_dependencies

# Verify bats is now available
if [[ ! -x "$BATS_BIN" ]]; then
  echo -e "${RED}Error: bats-core installation failed${NC}"
  exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       VOD CLI Test Suite              ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Change to test directory
cd "$SCRIPT_DIR"

# Run shellcheck first if available and not running specific test
if [[ -z "$SPECIFIC_TEST" ]] && check_shellcheck; then
  echo -e "${GREEN}Running shellcheck linting...${NC}"
  echo ""
  
  "$BATS_BIN" $VERBOSE shellcheck.bats
  echo ""
fi

# Run tests
if [[ -n "$SPECIFIC_TEST" ]]; then
  echo -e "${GREEN}Running: ${SPECIFIC_TEST}${NC}"
  echo ""
  
  "$BATS_BIN" $VERBOSE ${FILTER:+$FILTER} "$SPECIFIC_TEST"
else
  echo -e "${GREEN}Running all test files...${NC}"
  echo ""
  
  # Build list of test files (excluding shellcheck which ran above)
  other_tests=()
  for f in *.bats; do
    [[ "$f" != "shellcheck.bats" ]] && other_tests+=("$f")
  done
  
  echo -e "Found ${#other_tests[@]} test files (excluding shellcheck)"
  echo ""
  
  # Run all tests except shellcheck (already ran)
  
  "$BATS_BIN" $VERBOSE ${FILTER:+$FILTER} "${other_tests[@]}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}       Tests Complete                  ${NC}"
echo -e "${GREEN}========================================${NC}"
