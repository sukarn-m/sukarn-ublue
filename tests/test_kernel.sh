#!/usr/bin/env bash

# tests/test_kernel.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_SH="$SCRIPT_DIR/../files/scripts/kernel.sh"

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

test_dnf5_missing() {
    echo "Running test_dnf5_missing..."
    (
        # Mock command -v dnf5 to fail
        command() {
            if [[ "$1" == "-v" && "$2" == "dnf5" ]]; then
                return 1
            fi
            builtin command "$@"
        }
        # We need to export the function if we were calling a script,
        # but here we are sourcing the script and calling the function in the same subshell.
        source "$KERNEL_SH"
        set +e
        PREFERENCE_ORDER=("test")
        output=$(initial_sanity_check 2>&1)
        exit_code=$?
        assert_eq "$exit_code" "1" || exit 1
        assert_eq "$output" "Requires dnf5... Exiting" || exit 1
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_dnf5_missing${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_dnf5_missing (status $status)${NC}"
        ((failed++))
    fi
}

test_preference_order_empty() {
    echo "Running test_preference_order_empty..."
    (
        # Mock command -v dnf5 to succeed
        command() {
            if [[ "$1" == "-v" && "$2" == "dnf5" ]]; then
                echo "/usr/bin/dnf5"
                return 0
            fi
            builtin command "$@"
        }
        source "$KERNEL_SH"
        set +e
        PREFERENCE_ORDER=()
        output=$(initial_sanity_check 2>&1)
        exit_code=$?
        assert_eq "$exit_code" "1" || exit 1
        assert_eq "$output" "ERROR: PREFERENCE_ORDER not set." || exit 1
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_preference_order_empty${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_preference_order_empty (status $status)${NC}"
        ((failed++))
    fi
}

test_preference_order_unset() {
    echo "Running test_preference_order_unset..."
    (
        # Mock command -v dnf5 to succeed
        command() {
            if [[ "$1" == "-v" && "$2" == "dnf5" ]]; then
                echo "/usr/bin/dnf5"
                return 0
            fi
            builtin command "$@"
        }
        source "$KERNEL_SH"
        set +e
        unset PREFERENCE_ORDER
        output=$(initial_sanity_check 2>&1)
        exit_code=$?
        assert_eq "$exit_code" "1" || exit 1
        assert_eq "$output" "ERROR: PREFERENCE_ORDER not set." || exit 1
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_preference_order_unset${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_preference_order_unset (status $status)${NC}"
        ((failed++))
    fi
}

test_sanity_check_pass() {
    echo "Running test_sanity_check_pass..."
    (
        # Mock command -v dnf5 to succeed
        command() {
            if [[ "$1" == "-v" && "$2" == "dnf5" ]]; then
                echo "/usr/bin/dnf5"
                return 0
            fi
            builtin command "$@"
        }
        source "$KERNEL_SH"
        PREFERENCE_ORDER=("gated" "main")
        output=$(initial_sanity_check 2>&1)
        exit_code=$?
        assert_eq "$exit_code" "0" || exit 1
        assert_eq "$output" "" || exit 1
    )
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_sanity_check_pass${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_sanity_check_pass${NC}"
        ((failed++))
    fi
}

test_dnf5_missing
test_preference_order_empty
test_preference_order_unset
test_sanity_check_pass

echo "----------------------------"
echo "Tests passed: $passed"
echo "Tests failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
