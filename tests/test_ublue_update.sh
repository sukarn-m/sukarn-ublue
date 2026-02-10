#!/usr/bin/env bash

# tests/test_ublue_update.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UBLUE_UPDATE_SH="$SCRIPT_DIR/../files/scripts/ublue-update.sh"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

passed=0
failed=0

assert_eq() {
    if [[ "$1" == "$2" ]]; then
        return 0
    else
        echo -e "${RED}  Expected '$2', got '$1'${NC}"
        return 1
    fi
}

test_use_dnf_not_wget() {
    echo "Running test_use_dnf_not_wget..."
    (
        # Mock commands
        rpm() {
            return 1 # Assume not installed
        }
        rpm-ostree() {
            return 0
        }
        wget() {
            echo "CALLED_WGET $@"
            return 0
        }
        dnf5() {
            echo "CALLED_DNF5 $@"
            return 0
        }
        pip() {
            return 0
        }
        systemctl() {
            return 0
        }
        rm() {
            return 0
        }

        # Define OS_VERSION
        export OS_VERSION="38"

        # Source the script
        source "$UBLUE_UPDATE_SH"

        # Capture output
        output=$(main 2>&1)

        # Check if wget was called
        if [[ "$output" == *"CALLED_WGET"* ]]; then
            echo -e "${RED}FAIL: wget was called${NC}"
            echo "$output"
            exit 1
        fi

        # Check if dnf5 was called with correct args
        # Expected: dnf5 config-manager addrepo --from-repofile=... --overwrite --save-filename=...
        EXPECTED_REPO="https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-38/ublue-os-staging-fedora-38.repo"
        EXPECTED_FILENAME="ublue-os-staging-fedora-38.repo"
        if [[ "$output" != *"CALLED_DNF5 config-manager addrepo --from-repofile=$EXPECTED_REPO --overwrite --save-filename=$EXPECTED_FILENAME"* ]]; then
             echo -e "${RED}FAIL: dnf5 was not called correctly${NC}"
             echo "Expected to contain: CALLED_DNF5 config-manager addrepo --from-repofile=$EXPECTED_REPO --overwrite --save-filename=$EXPECTED_FILENAME"
             echo "Output: $output"
             exit 1
        fi
    )

    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_use_dnf_not_wget${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_use_dnf_not_wget (status $status)${NC}"
        ((failed++))
    fi
}

test_use_dnf_not_wget

echo "----------------------------"
echo "Tests passed: $passed"
echo "Tests failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
