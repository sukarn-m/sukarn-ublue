#!/bin/bash

# Source the script but avoid execution of main
# We need to be careful with set -e which is in kernel.sh
# We'll rely on it for now.

source ./files/scripts/kernel.sh

# Mock globals
PREFERENCE_ORDER=()
VARIANTS_TRIED=()
VARIANT_CURRENT=""
BAZZITE_ONLY="0"

# Helper for assertions
assert_eq() {
  if [[ "$1" != "$2" ]]; then
    echo "FAIL: Expected '$2', got '$1'"
    exit 1
  fi
}

echo "Running tests..."

# Test 1: Standard fallback
echo "Test 1: Standard fallback"
PREFERENCE_ORDER=("v1" "v2" "v3")
VARIANTS_TRIED=()
VARIANT_CURRENT="v1"
BAZZITE_ONLY="0"

set_next_variant

assert_eq "$VARIANT_CURRENT" "v2"
# VARIANTS_TRIED should contain v1
found=0
for v in "${VARIANTS_TRIED[@]}"; do
  if [[ "$v" == "v1" ]]; then found=1; break; fi
done
assert_eq "$found" "1"

# Test 2: Skip already tried variants
echo "Test 2: Skip already tried variants"
PREFERENCE_ORDER=("v1" "v2" "v3")
VARIANTS_TRIED=("v1")
VARIANT_CURRENT="v2"
BAZZITE_ONLY="0"

set_next_variant

assert_eq "$VARIANT_CURRENT" "v3"
# v2 should have been added to tried list
found=0
for v in "${VARIANTS_TRIED[@]}"; do
  if [[ "$v" == "v2" ]]; then found=1; break; fi
done
assert_eq "$found" "1"


# Test 3: Bazzite only filtering
echo "Test 3: Bazzite only filtering"
PREFERENCE_ORDER=("v1" "bazzite-v2" "v3" "bazzite-v4")
VARIANTS_TRIED=()
VARIANT_CURRENT="v1"
BAZZITE_ONLY="1"

set_next_variant
assert_eq "$VARIANT_CURRENT" "bazzite-v2"

# Continue from bazzite-v2
VARIANTS_TRIED=("v1" "bazzite-v2")
VARIANT_CURRENT="bazzite-v2"

set_next_variant
assert_eq "$VARIANT_CURRENT" "bazzite-v4"


# Test 4: Exhaustion
echo "Test 4: Exhaustion"
PREFERENCE_ORDER=("v1")
VARIANTS_TRIED=()
VARIANT_CURRENT="v1"
BAZZITE_ONLY="0"

if (set_next_variant) 2>/dev/null; then
  echo "FAIL: Should have exited"
  exit 1
else
  echo "PASS: Exited correctly"
fi

# Test 5: Invalid configuration
echo "Test 5: Invalid configuration"
PREFERENCE_ORDER=("v1" "v2")
VARIANTS_TRIED=()
VARIANT_CURRENT="v1"
BAZZITE_ONLY="2"

if (set_next_variant) 2>/dev/null; then
  echo "FAIL: Should have exited due to invalid BAZZITE_ONLY"
  exit 1
else
  echo "PASS: Exited correctly"
fi

# Test 6: Variants with spaces
echo "Test 6: Variants with spaces"
PREFERENCE_ORDER=("variant one" "variant two")
VARIANTS_TRIED=()
VARIANT_CURRENT="variant one"
BAZZITE_ONLY="0"

set_next_variant

assert_eq "$VARIANT_CURRENT" "variant two"

echo "All tests passed!"
