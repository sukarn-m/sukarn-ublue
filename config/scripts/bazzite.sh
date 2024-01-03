#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# Nvidia specific stuff
file_path="/usr/bin/bazzite-hardware-setup"
sed -i "s,^IMAGE_FLAVOR=.*,IMAGE_FLAVOR=nvidia," ${file_path}

# Logo / branding stuff
rm -v /usr/share/pixmaps/fedora_whitelogo.svg
