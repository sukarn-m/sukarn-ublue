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

test_initial_config_defaults() {
    echo "Running test_initial_config_defaults..."
    (
        source "$KERNEL_SH"

        # Mocks
        rpm() {
            if [[ "$1" == "-q" && "$2" == "kernel" ]]; then
                echo "kernel-6.8.0-1.fc40.x86_64"
            elif [[ "$1" == "-E" && "$2" == "%fedora" ]]; then
                echo "40"
            else
                command rpm "$@"
            fi
        }
        hostnamectl() {
            echo "my-host"
        }

        # Run
        user_config
        initial_config

        # Assertions
        assert_eq "$NVIDIA_WANTED" "0" || exit 1
        assert_eq "$BAZZITE_ONLY" "0" || exit 1
        assert_eq "$VARIANT_CURRENT" "gated" || exit 1
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_initial_config_defaults${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_initial_config_defaults (status $status)${NC}"
        ((failed++))
    fi
}

test_initial_config_bazzite_file() {
    echo "Running test_initial_config_bazzite_file..."
    (
        source "$KERNEL_SH"

        # Mocks
        rpm() { echo "mock"; }
        hostnamectl() { echo "mock"; }

        # Setup
        touch /tmp/bazzite-only

        # Run
        user_config
        initial_config

        # Assertions
        assert_eq "$BAZZITE_ONLY" "1" || exit 1
        if [[ -f /tmp/bazzite-only ]]; then
             echo -e "${RED}  /tmp/bazzite-only was not removed${NC}"
             exit 1
        fi
        assert_eq "$VARIANT_CURRENT" "bazzite" || exit 1
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_initial_config_bazzite_file${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_initial_config_bazzite_file (status $status)${NC}"
        ((failed++))
    fi
}

test_initial_config_nvidia_file() {
    echo "Running test_initial_config_nvidia_file..."
    (
        source "$KERNEL_SH"

        # Mocks
        rpm() { echo "mock"; }
        hostnamectl() { echo "mock"; }

        # Setup
        touch /tmp/nvidia

        # Run
        user_config
        initial_config

        # Assertions
        assert_eq "$NVIDIA_WANTED" "1" || exit 1
        if [[ -f /tmp/nvidia ]]; then
             echo -e "${RED}  /tmp/nvidia was not removed${NC}"
             exit 1
        fi
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_initial_config_nvidia_file${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_initial_config_nvidia_file (status $status)${NC}"
        ((failed++))
    fi
}

test_reset_vars() {
    echo "Running test_reset_vars..."
    (
        source "$KERNEL_SH"

        # Mock initial_config variables that reset_vars might depend on if strict mode is on?
        # reset_vars uses VARIANT_CURRENT, GATED_TAG.

        # Case 1: bazzite
        VARIANT_CURRENT="bazzite"
        GATED_TAG="coreos-stable"
        reset_vars
        assert_eq "$AKMODS_FLAVOUR" "bazzite" || exit 1

        # Case 2: gated
        VARIANT_CURRENT="gated"
        GATED_TAG="coreos-stable"
        reset_vars
        assert_eq "$AKMODS_FLAVOUR" "coreos-stable" || exit 1

        # Case 3: main
        VARIANT_CURRENT="main"
        GATED_TAG="coreos-stable"
        reset_vars
        assert_eq "$AKMODS_FLAVOUR" "main" || exit 1

        # Case 4: bazzite-gated
        VARIANT_CURRENT="bazzite-gated"
        GATED_TAG="coreos-stable"
        reset_vars
        assert_eq "$AKMODS_FLAVOUR" "bazzite" || exit 1
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_reset_vars${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_reset_vars (status $status)${NC}"
        ((failed++))
    fi
}

test_set_next_variant() {
    echo "Running test_set_next_variant..."
    (
        source "$KERNEL_SH"

        # Mocking
        PREFERENCE_ORDER=("A" "B" "C")
        BAZZITE_ONLY="0"

        # Test 1: Start with A, next should be B
        VARIANTS_TRIED=()
        VARIANT_CURRENT="A"
        set_next_variant
        assert_eq "$VARIANT_CURRENT" "B" || exit 1

        # Test 2: Tried A, currently B, next C
        VARIANTS_TRIED=("A")
        VARIANT_CURRENT="B"
        set_next_variant
        assert_eq "$VARIANT_CURRENT" "C" || exit 1

    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_set_next_variant${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_set_next_variant (status $status)${NC}"
        ((failed++))
    fi
}

test_akmod_sanity_check() {
    echo "Running test_akmod_sanity_check..."
    (
        source "$KERNEL_SH"

        # Setup temp dir (mocking /tmp/akmods/kmods)
        # Since script uses hardcoded path, we have to use it.
        # But we must clean up.

        rm -rf /tmp/akmods
        mkdir -p /tmp/akmods/kmods

        AKMODS_WANTED=("foo" "bar")

        # Create matching files
        touch /tmp/akmods/kmods/kmod-foo-1.rpm
        touch /tmp/akmods/kmods/kmod-bar-1.rpm

        akmod_sanity_check

        # Cleanup
        rm -rf /tmp/akmods
    )
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}PASS: test_akmod_sanity_check${NC}"
        ((passed++))
    else
        echo -e "${RED}FAIL: test_akmod_sanity_check (status $status)${NC}"
        ((failed++))
    fi
}

# Run tests
test_dnf5_missing
test_preference_order_empty
test_preference_order_unset
test_sanity_check_pass
test_initial_config_defaults
test_initial_config_bazzite_file
test_initial_config_nvidia_file
test_reset_vars
test_set_next_variant
test_akmod_sanity_check

echo "----------------------------"
echo "Tests passed: $passed"
echo "Tests failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
