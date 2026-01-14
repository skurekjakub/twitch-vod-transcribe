#!/usr/bin/env bats

# Tests for scripts/unmount-nas.sh

setup() {
  load 'test_helper/common-setup'
  _common_setup
}

teardown() {
  _common_teardown
}

@test "unmount-nas.sh --help shows usage" {
  run "${SCRIPTS_DIR}/unmount-nas.sh" --help
  assert_success
  assert_output --partial "Unmount NAS"
  assert_output --partial "Usage: vod unmount-nas"
}

@test "unmount-nas.sh no-ops when /nas not mounted" {
  local mounts_file="${TEST_TEMP_DIR}/mounts"
  echo "tmpfs / tmpfs rw 0 0" > "$mounts_file"

  run env PROC_MOUNTS_FILE="$mounts_file" "${SCRIPTS_DIR}/unmount-nas.sh"
  assert_success
  assert_output --partial "NAS is not mounted"
}

@test "unmount-nas.sh calls umount when /nas mounted" {
  local mounts_file="${TEST_TEMP_DIR}/mounts"
  echo "nas:/share /nas cifs rw 0 0" > "$mounts_file"

  create_mock "umount" 0 ""

  run env PROC_MOUNTS_FILE="$mounts_file" "${SCRIPTS_DIR}/unmount-nas.sh"
  assert_success
  assert_output --partial "Force unmounting /nas"
  assert_output --partial "NAS unmounted (/nas)"

  assert_mock_called "umount"
  assert_mock_called_with "umount" "/nas"
}
