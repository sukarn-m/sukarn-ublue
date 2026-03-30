#!/usr/bin/env bash

# tests/test_install_libation.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_LIBATION_SH="$SCRIPT_DIR/../files/scripts/install_libation.sh"

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

test_secure_directory() {
    echo "Running test_secure_directory..."
    (
        # Mock commands
        curl() {
            echo ' "browser_download_url": "https://github.com/rmcrackan/Libation/releases/download/v1.0.0/Libation-1.0.0-amd64.rpm" '
        }
        wget() {
            echo "WGET_ARGS: $@"
            # Find -O argument
            local o_arg=""
            while [[ $# -gt 0 ]]; do
                if [[ "$1" == "-O" ]]; then
                    o_arg="$2"
                    shift 2
                else
                    shift
                fi
            done

            # Verify the directory is random
            if [[ "$o_arg" =~ ^/tmp/tmp\..*/Libation-1.0.0-amd64.rpm$ ]]; then
                echo "SECURE_DOWNLOAD_PATH_DETECTED"
                # Store the directory name for later cleanup check
                echo "${o_arg%/Libation-1.0.0-amd64.rpm}" > /tmp/test_last_tmp_dir
            fi

            # Create a mock file so the script continues
            mkdir -p "$(dirname "$o_arg")"
            touch "$o_arg"
            return 0
        }
        rpm-ostree() {
            echo "RPM_OSTREE_ARGS: $@"
            if [[ "$2" =~ ^/tmp/tmp\..*/Libation-1.0.0-amd64.rpm$ ]]; then
                echo "SECURE_INSTALL_PATH_DETECTED"
            fi
            return 0
        }

        export -f curl
        export -f wget
        export -f rpm-ostree

        # Source the script. Note that sourcing will trigger trap if we don't handle it
        # Actually, trap on EXIT in a sourced script will run when the *shell* exits.
        # But we are in a subshell.
        source "$INSTALL_LIBATION_SH"

        # Run check_and_install
        output=$(check_and_install 2>&1)

        echo "$output"

        if [[ "$output" == *"SECURE_DOWNLOAD_PATH_DETECTED"* ]]; then
            echo "Secure download path confirmed."
        else
            echo "Secure download path NOT detected."
            exit 1
        fi

        if [[ "$output" == *"SECURE_INSTALL_PATH_DETECTED"* ]]; then
            echo "Secure install path confirmed."
        else
            echo "Secure install path NOT detected."
            exit 1
        fi

        # Now we exit the subshell, the trap should trigger
    )

    # Check if the temporary directory was removed
    if [[ -f /tmp/test_last_tmp_dir ]]; then
        dir_to_check=$(cat /tmp/test_last_tmp_dir)
        if [[ -d "$dir_to_check" ]]; then
            echo "FAIL: Temporary directory $dir_to_check was NOT removed."
            exit 1
        else
            echo "PASS: Temporary directory was removed."
        fi
        rm /tmp/test_last_tmp_dir
    fi

    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_secure_directory verified fix${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_secure_directory failed (status $status)${NC}"
        ((failed++))
    fi
}

test_secure_directory

echo "----------------------------"
echo "Tests passed: $passed"
echo "Tests failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
