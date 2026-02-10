#!/usr/bin/env bash

# tests/test_install_libation.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/../files/scripts/install_libation.sh"

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

test_extract_version_standard() {
    echo "Running test_extract_version_standard..."
    (
        source "$TARGET_SCRIPT"
        # Test with known format
        result=$(extract_version "Libation.13.1.8-linux-chardonnay-amd64.rpm")
        assert_eq "$result" "13.1.8" || exit 1
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_extract_version_standard${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_extract_version_standard${NC}"
        ((failed++))
    fi
}

test_extract_version_edge_cases() {
    echo "Running test_extract_version_edge_cases..."
    (
        source "$TARGET_SCRIPT"
        # Test with potential variations

        # New logic: grep -oE '[0-9]+\.[0-9]+\.[0-9]+'

        # Hypothetical: Libation-1.2.3.rpm -> 1.2.3
        result=$(extract_version "Libation-1.2.3.rpm")
        assert_eq "$result" "1.2.3" || exit 1

        # Hypothetical: Libation.100.0.1.rpm -> 100.0.1
        result=$(extract_version "Libation.100.0.1.rpm")
        assert_eq "$result" "100.0.1" || exit 1
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_extract_version_edge_cases${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_extract_version_edge_cases${NC}"
        ((failed++))
    fi
}

test_check_and_install_new_install() {
    echo "Running test_check_and_install_new_install..."
    (
        source "$TARGET_SCRIPT"

        # Mocks (override functions from script)
        get_latest_release_url() {
            echo "https://example.com/Libation.2.0.0.rpm"
        }

        mkdir() { echo "mkdir $@" >&2; }
        rm() { echo "rm $@" >&2; }
        wget() { echo "wget $@" >&2; }
        rpm-ostree() { echo "rpm-ostree $@" >&2; }

        ls() { return 2; }

        output=$(check_and_install 2>&1)

        if ! echo "$output" | grep -q "wget .*Libation.2.0.0.rpm"; then
            echo -e "${RED}  Expected wget call not found${NC}"
            echo "Output: $output"
            exit 1
        fi

        if ! echo "$output" | grep -q "rpm-ostree install /tmp/libation/Libation.2.0.0.rpm"; then
            echo -e "${RED}  Expected rpm-ostree call not found${NC}"
            echo "Output: $output"
            exit 1
        fi

        if ! echo "$output" | grep -q "rm -r /tmp/libation"; then
             echo -e "${RED}  Expected rm -r call not found${NC}"
             echo "Output: $output"
             exit 1
        fi
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_check_and_install_new_install${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_check_and_install_new_install${NC}"
        ((failed++))
    fi
}

test_check_and_install_update() {
    echo "Running test_check_and_install_update..."
    (
        source "$TARGET_SCRIPT"

        # Override functions
        get_latest_release_url() {
            echo "https://example.com/Libation.2.0.0.rpm"
        }

        mkdir() { :; }
        rm() { echo "rm $@" >&2; }
        wget() { echo "wget $@" >&2; }
        rpm-ostree() { echo "rpm-ostree $@" >&2; }

        ls() {
            if [[ "$*" == *"/tmp/libation/Libation"*"rpm" ]]; then
                echo "/tmp/libation/Libation.1.0.0.rpm"
                return 0
            fi
            return 2
        }

        output=$(check_and_install 2>&1)

        if ! echo "$output" | grep -q "rm -v /tmp/libation/Libation\*.rpm"; then
             echo -e "${RED}  Expected rm -v for old file not found${NC}"
             echo "Output: $output"
             exit 1
        fi

        if ! echo "$output" | grep -q "wget"; then
             echo -e "${RED}  Expected wget call not found${NC}"
             echo "Output: $output"
             exit 1
        fi
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_check_and_install_update${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_check_and_install_update${NC}"
        ((failed++))
    fi
}

test_check_and_install_no_update() {
    echo "Running test_check_and_install_no_update..."
    (
        source "$TARGET_SCRIPT"

        # Override functions
        get_latest_release_url() {
            echo "https://example.com/Libation.2.0.0.rpm"
        }

        mkdir() { :; }
        rm() { echo "rm $@" >&2; }
        wget() { echo "wget $@" >&2; }
        rpm-ostree() { echo "rpm-ostree $@" >&2; }

        ls() {
            if [[ "$*" == *"/tmp/libation/Libation"*"rpm" ]]; then
                echo "/tmp/libation/Libation.2.0.0.rpm"
                return 0
            fi
            return 2
        }

        output=$(check_and_install 2>&1)

        if echo "$output" | grep -q "rm -v /tmp/libation/Libation\*.rpm"; then
             echo -e "${RED}  Unexpected rm -v for old file found${NC}"
             echo "Output: $output"
             exit 1
        fi

        if echo "$output" | grep -q "wget"; then
             echo -e "${RED}  Unexpected wget call found${NC}"
             echo "Output: $output"
             exit 1
        fi

        if ! echo "$output" | grep -q "rpm-ostree install"; then
             echo -e "${RED}  Expected rpm-ostree call not found${NC}"
             echo "Output: $output"
             exit 1
        fi
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_check_and_install_no_update${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_check_and_install_no_update${NC}"
        ((failed++))
    fi
}

# Run tests
test_extract_version_standard
test_extract_version_edge_cases
test_check_and_install_new_install
test_check_and_install_update
test_check_and_install_no_update

echo "----------------------------"
echo "Tests passed: $passed"
echo "Tests failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
