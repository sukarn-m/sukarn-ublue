#!/bin/bash
set -u

# Mock rpm
rpm() {
    if [[ "$1" == "-E" ]]; then
        echo "39"
    elif [[ "$1" == "-qa" ]]; then
        echo "kernel-6.8.9-300.fc39.x86_64"
    else
        echo "rpm mock called with: $@" >&2
    fi
}
export -f rpm

# Mock rpm-ostree
rpm-ostree() {
    echo "rpm-ostree mock called with: $@" >&2
}
export -f rpm-ostree

# Mock curl that fails for specific URL
curl() {
    echo "curl mock called with: $@" >&2
    # Fail if the URL contains "rpmfusion"
    if [[ "$@" == *"rpmfusion"* ]]; then
        echo "Simulating failure for rpmfusion" >&2
        return 1
    fi
    sleep 0.1
}
export -f curl

echo "Running script expecting failure..."
# We expect the script to fail, so we negate the exit code logic
if bash files/scripts/fedora-atomic-repos.sh; then
    echo "FAILURE: Script succeeded but should have failed."
    exit 1
else
    echo "SUCCESS: Script failed as expected."
fi
