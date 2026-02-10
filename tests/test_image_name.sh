#!/usr/bin/env bash

# Test script for image_name.sh

# Create temp files
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

OS_RELEASE_FILE="$TMP_DIR/os-release"
FEDORA_RELEASE_FILE="$TMP_DIR/fedora-release"

# Populate temp files
echo "Fedora release 39 (Thirty Nine)" > "$FEDORA_RELEASE_FILE"
echo 'PRETTY_NAME="Fedora Linux 39 (Workstation Edition)"' > "$OS_RELEASE_FILE"

# Export variables for the script
export OS_RELEASE_FILE
export FEDORA_RELEASE_FILE

# Test 1: Default behavior (Sukarn Linux)
export IMAGE_DISTRO_NAME="Sukarn Linux"
bash files/scripts/image_name.sh

# Check if file was updated
if grep -q "Sukarn Linux 39" "$OS_RELEASE_FILE"; then
    echo "Test 1 Passed: Sukarn Linux found"
else
    echo "Test 1 Failed: Sukarn Linux not found in $(cat "$OS_RELEASE_FILE")"
    exit 1
fi

# Reset file
echo 'PRETTY_NAME="Fedora Linux 39 (Workstation Edition)"' > "$OS_RELEASE_FILE"

# Test 2: Custom behavior (Fedora Linux)
export IMAGE_DISTRO_NAME="Fedora Linux"
bash files/scripts/image_name.sh

# Check if file was updated
if grep -q "Fedora Linux 39" "$OS_RELEASE_FILE"; then
    echo "Test 2 Passed: Fedora Linux found"
else
    echo "Test 2 Failed: Fedora Linux not found in $(cat "$OS_RELEASE_FILE")"
    exit 1
fi

echo "All tests passed!"
