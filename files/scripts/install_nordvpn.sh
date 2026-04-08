#!/usr/bin/env bash
set -oue pipefail

echo "Installing NordVPN..."
echo y | sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
