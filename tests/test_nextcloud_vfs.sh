#!/usr/bin/env bash
set -e

# Mock ln command
ln() {
    echo "MOCK_LN: $@"
}
export -f ln

# Path to the script under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/../files/scripts/nextcloud-vfs.sh"

echo "Running test for $SCRIPT_PATH"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: Script not found at $SCRIPT_PATH"
    exit 1
fi

# Run the script and capture output
# We use bash to run it, which inherits exported functions
OUTPUT=$(bash "$SCRIPT_PATH")

# Verify expected calls
EXPECTED_1="MOCK_LN: -s -v /usr/lib64/nextcloudsync_vfs_suffix.so /usr/lib64/qt6/plugins/nextcloudsync_vfs_suffix.so"
EXPECTED_2="MOCK_LN: -s -v /usr/lib64/nextcloudsync_vfs_xattr.so /usr/lib64/qt6/plugins/nextcloudsync_vfs_xattr.so"

FAILED=0

if echo "$OUTPUT" | grep -Fq "$EXPECTED_1"; then
    echo "PASS: First symlink creation attempted."
else
    echo "FAIL: First symlink creation missing or incorrect."
    echo "Expected: $EXPECTED_1"
    FAILED=1
fi

if echo "$OUTPUT" | grep -Fq "$EXPECTED_2"; then
    echo "PASS: Second symlink creation attempted."
else
    echo "FAIL: Second symlink creation missing or incorrect."
    echo "Expected: $EXPECTED_2"
    FAILED=1
fi

if [ "$FAILED" -eq 1 ]; then
    echo "Test failed."
    echo "Output was:"
    echo "$OUTPUT"
    exit 1
fi

echo "All tests passed for nextcloud-vfs.sh"
