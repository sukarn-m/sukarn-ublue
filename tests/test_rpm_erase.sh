#!/usr/bin/env bash

# tests/test_rpm_erase.sh

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

test_rpm_erase_batch() {
    echo "Running test_rpm_erase_batch..."
    (
        # Mock rpm
        rpm() {
            if [[ "$1" == "-q" ]]; then
                # Simulate that kernel, kernel-core, and kernel-modules are installed
                if [[ "$2" == "kernel" || "$2" == "kernel-core" || "$2" == "kernel-modules" ]]; then
                    return 0
                else
                    return 1
                fi
            elif [[ "$1" == "--erase" ]]; then
                echo "rpm_erase_called: ${@:2}"
                return 0
            fi
        }
        export -f rpm

        source "$KERNEL_SH"

        # Capture output
        output=$(rpm_erase)

        # Expected output: "rpm_erase_called: kernel kernel-core kernel-modules --nodeps"
        # The order depends on the loop order in kernel.sh
        # In kernel.sh: kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt
        # So we expect kernel, kernel-core, kernel-modules.

        expected="rpm_erase_called: kernel kernel-core kernel-modules --nodeps"

        if [[ "$output" == *"$expected"* ]]; then
             echo -e "${GREEN}PASS: test_rpm_erase_batch${NC}"
             exit 0
        else
             echo -e "${RED}FAIL: test_rpm_erase_batch${NC}"
             echo "Output: $output"
             echo "Expected: $expected"
             exit 1
        fi
    )
    if [[ $? -eq 0 ]]; then
        ((passed++))
    else
        ((failed++))
    fi
}

test_rpm_erase_none() {
    echo "Running test_rpm_erase_none..."
    (
        # Mock rpm - nothing installed
        rpm() {
            if [[ "$1" == "-q" ]]; then
                return 1
            elif [[ "$1" == "--erase" ]]; then
                echo "rpm_erase_called: ${@:2}"
                return 0
            fi
        }
        export -f rpm

        source "$KERNEL_SH"

        output=$(rpm_erase)

        if [[ -z "$output" ]]; then
             echo -e "${GREEN}PASS: test_rpm_erase_none${NC}"
             exit 0
        else
             echo -e "${RED}FAIL: test_rpm_erase_none${NC}"
             echo "Output should be empty, got: $output"
             exit 1
        fi
    )
    if [[ $? -eq 0 ]]; then
        ((passed++))
    else
        ((failed++))
    fi
}


test_rpm_erase_batch
test_rpm_erase_none

echo "----------------------------"
echo "Tests passed: $passed"
echo "Tests failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
