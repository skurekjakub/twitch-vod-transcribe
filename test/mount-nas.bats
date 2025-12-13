#!/usr/bin/env bats

load 'test_helper/common-setup'

setup() {
  _common_setup

  # Store original script path
  MOUNT_NAS_SCRIPT="$PROJECT_ROOT/scripts/mount-nas.sh"
  
  # Create a temporary test directory
  TEST_DIR="$(mktemp -d)"
  export VOD_ROOT_DIR="$TEST_DIR"
  
  # Create fake mount/umount commands
  export PATH="$TEST_DIR/bin:$PATH"
  mkdir -p "$TEST_DIR/bin"
  
  # Create a mock mount command
  cat > "$TEST_DIR/bin/mount" << 'EOF'
#!/bin/bash
echo "mock mount called with: $@" >&2
exit 0
EOF
  chmod +x "$TEST_DIR/bin/mount"
  
  # Create fake /proc/mounts
  export PROC_MOUNTS_FILE="$TEST_DIR/proc_mounts"
  touch "$PROC_MOUNTS_FILE"
  
  # Create a sample .env.local
  cat > "$TEST_DIR/.env.local" << 'EOF'
NAS_HOST=192.168.1.100
NAS_SHARE=media
NAS_USER=testuser
NAS_PASS=testpass
EOF
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "mount-nas.sh exists and is executable" {
  [ -x "$MOUNT_NAS_SCRIPT" ]
}

@test "mount-nas.sh shows help with --help" {
  run "$MOUNT_NAS_SCRIPT" --help
  assert_success
  assert_output --partial "Mount NAS"
  assert_output --partial "Usage: vod mount-nas"
  assert_output --partial "NAS_HOST"
  assert_output --partial "NAS_SHARE"
}

@test "mount-nas.sh shows help with -h" {
  run "$MOUNT_NAS_SCRIPT" -h
  assert_success
  assert_output --partial "Mount NAS"
}

@test "mount-nas.sh rejects unknown arguments" {
  run "$MOUNT_NAS_SCRIPT" --invalid-option
  assert_failure
  assert_output --partial "Error: Unknown argument"
}

@test "mount-nas.sh fails if .env.local is missing" {
  rm "$TEST_DIR/.env.local"
  
  run "$MOUNT_NAS_SCRIPT"
  assert_failure
  assert_output --partial "Error: .env.local not found"
}

@test "mount-nas.sh fails if NAS_HOST is missing" {
  cat > "$TEST_DIR/.env.local" << 'EOF'
NAS_SHARE=media
EOF
  
  run "$MOUNT_NAS_SCRIPT"
  assert_failure
  assert_output --partial "Error: NAS_HOST and NAS_SHARE must be defined"
}

@test "mount-nas.sh fails if NAS_SHARE is missing" {
  cat > "$TEST_DIR/.env.local" << 'EOF'
NAS_HOST=192.168.1.100
EOF
  
  run "$MOUNT_NAS_SCRIPT"
  assert_failure
  assert_output --partial "Error: NAS_HOST and NAS_SHARE must be defined"
}

@test "mount-nas.sh skips if already mounted" {
  echo "cifs /nas cifs rw 0 0" > "$PROC_MOUNTS_FILE"
  
  run "$MOUNT_NAS_SCRIPT"
  assert_success
  assert_output --partial "already mounted"
}

@test "mount-nas.sh loads credentials and mounts" {
  run "$MOUNT_NAS_SCRIPT"
  assert_success
  assert_output --partial "Loading NAS credentials"
  assert_output --partial "Mounting NAS at /nas"
  assert_output --partial "mounted successfully"
}

@test "mount-nas.sh uses guest mode if NAS_USER/NAS_PASS not set" {
  cat > "$TEST_DIR/.env.local" << 'EOF'
NAS_HOST=192.168.1.100
NAS_SHARE=media
EOF
  
  run "$MOUNT_NAS_SCRIPT"
  assert_success
  assert_output --partial "using guest access"
}

@test "mount-nas.sh hides password in displayed output" {
  run "$MOUNT_NAS_SCRIPT"
  assert_success
  # Password should be hidden in the user-facing output line
  assert_output --partial "password=***"
  # Note: Mock command output in stderr may still contain password, but user-facing output is masked
}

@test "vod mount-nas command works" {
  # Use the real vod script but with our test environment
  run "$PROJECT_ROOT/vod" mount-nas
  assert_success
}

@test "vod mount-nas --help shows help" {
  run "$PROJECT_ROOT/vod" mount-nas --help
  assert_success
  assert_output --partial "Mount NAS"
}
