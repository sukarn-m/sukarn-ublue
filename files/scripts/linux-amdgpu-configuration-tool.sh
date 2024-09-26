#!/usr/bin/bash

set -oue pipefail

## For GNOME based images such as silverblue-main
echo 'Installing LACT Libadwaita...'
wget \
$(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | \
jq -r ".assets[] | select(.name | test(\"lact-libadwaita.*fedora-$(rpm -E %fedora)\")) | .browser_download_url") \
-O /tmp/lact.rpm

## For other images
# echo 'Installing LACT...'
# wget \
# $(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | \
# jq -r ".assets[] | select(.name | test(\"lact-[0-9].*fedora-$(rpm -E %fedora)\")) | .browser_download_url") \
# -O /tmp/lact.rpm

## Common to both options above
rpm-ostree install -y /tmp/lact.rpm
rm /tmp/lact.rpm
