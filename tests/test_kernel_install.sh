#!/usr/bin/bash

# Mock environment
export FEDORA_VERSION=40
if [[ -z "${AKMODS_WANTED_STR:-}" ]]; then
  AKMODS_WANTED=("xone" "v4l2loopback")
else
  # Split string into array
  IFS=',' read -r -a AKMODS_WANTED <<< "$AKMODS_WANTED_STR"
fi
export KERNEL_PRE="6.8.0"

# Counter for dnf5 calls
DNF5_CALLS=0

# Mock dnf5
function dnf5() {
  DNF5_CALLS=$((DNF5_CALLS+1))
  echo "dnf5 called with: $@"
}
export -f dnf5

# Mock rpm
function rpm() {
  if [[ "$1" == "-q" ]]; then
    if [[ "$2" == "kernel" ]]; then
      echo "kernel-6.8.0"
    elif [[ "$2" == "kernel-tools" ]]; then
      return 0 # installed
    fi
  elif [[ "$1" == "-E" ]]; then
      echo "40"
  fi
}
export -f rpm

# Mock tree (used in list_packages but we don't care about it for benchmark, but script calls it)
function tree() {
  return 0
}
export -f tree

# Setup files
# Clean up first
rm -rf /tmp/akmods /tmp/kernel-rpms

mkdir -p /tmp/akmods/kmods
mkdir -p /tmp/kernel-rpms
touch /tmp/akmods/kmods/kmod-xone-1.0.rpm
touch /tmp/akmods/kmods/kmod-v4l2loopback-1.0.rpm
touch /tmp/kernel-rpms/kernel-core.rpm

# Source the script
source files/scripts/kernel.sh

# Run install_packages
echo "Running install_packages with AKMODS_WANTED=${AKMODS_WANTED[@]}"
install_packages

echo "Total dnf5 calls: $DNF5_CALLS"

# Assertions
if [[ "${#AKMODS_WANTED[@]}" -eq 2 ]]; then
  # xone + v4l2loopback: 4 calls
  if [[ "$DNF5_CALLS" -ne 4 ]]; then
    echo "FAIL: Expected 4 calls, got $DNF5_CALLS"
    exit 1
  fi
elif [[ "${#AKMODS_WANTED[@]}" -eq 1 ]]; then
  # xone: 2 calls
  if [[ "$DNF5_CALLS" -ne 2 ]]; then
    echo "FAIL: Expected 2 calls, got $DNF5_CALLS"
    exit 1
  fi
fi

echo "PASS"
