#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/../files/scripts/fedora-atomic-repos.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

passed=0
failed=0

test_use_dnf_for_repos() {
    echo "Running test_use_dnf_for_repos..."
    (
        # Mock commands
        rpm() {
            if [[ "$1" == "-E" && "$2" == "%fedora" ]]; then
                echo "38"
            elif [[ "$1" == "-qa" ]]; then
                echo "kernel-6.2.9-300.fc38.x86_64"
            else
                echo "rpm called with $@"
            fi
        }
        curl() {
            # curl -Lo /path url
            local output_file="$2"
            echo "CALLED_CURL output=$output_file args=$@"
            return 0
        }
        dnf5() {
            echo "CALLED_DNF5 $@"
            return 0
        }
        rpm-ostree() {
            echo "CALLED_RPM_OSTREE $@"
            return 0
        }
        mkdir() {
            return 0
        }
        rm() {
            return 0
        }

        # Source the script
        # We need to ensure set -e doesn't kill the test if a mock returns non-zero, but here mocks return 0.
        source "$TARGET_SCRIPT" 2>&1 | tee /tmp/test_output.log
    )

    # Capture the exit code of the subshell
    local status=$?
    if [[ $status -ne 0 ]]; then
        echo -e "${RED}FAIL: script execution failed${NC}"
        ((failed++))
        return 1
    fi

    output=$(cat /tmp/test_output.log)

    # Check for curl calls to /etc/yum.repos.d/
    if echo "$output" | grep -q "CALLED_CURL output=/etc/yum.repos.d/"; then
        echo -e "${RED}FAIL: curl was used to download a repo file${NC}"
        # print the offending line
        echo "$output" | grep "CALLED_CURL output=/etc/yum.repos.d/"
        ((failed++))
        return 1
    fi

    # Check for dnf5 config-manager calls
    # We expect 4 repo files to be added.
    # _copr_ublue-os_staging.repo
    # _copr_kylegospo_oversteer.repo
    # _copr_ublue-os-akmods.repo
    # negativo17-fedora-multimedia.repo

    expected_repos=(
        "_copr_ublue-os_staging.repo"
        "_copr_kylegospo_oversteer.repo"
        "_copr_ublue-os-akmods.repo"
        "negativo17-fedora-multimedia.repo"
    )

    local missing_repo=0
    for repo in "${expected_repos[@]}"; do
        if ! echo "$output" | grep -q "CALLED_DNF5 config-manager addrepo .* --save-filename=$repo"; then
            echo -e "${RED}FAIL: dnf5 was not called for $repo${NC}"
            missing_repo=1
        fi
    done

    if [[ $missing_repo -eq 1 ]]; then
        ((failed++))
        return 1
    fi

    echo -e "${GREEN}PASS: test_use_dnf_for_repos${NC}"
    ((passed++))
}

# Run test
test_use_dnf_for_repos

echo "----------------------------"
echo "Tests passed: $passed"
echo "Tests failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
