#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# Nvidia specific stuff
file_path="/usr/bin/bazzite-hardware-setup"
sed -i "s,^IMAGE_FLAVOR=.*,IMAGE_FLAVOR=nvidia," ${file_path}

# Nvidia specific Gnome flickering / tearing fix
echo "# Gnome flickering / tearing fix" >> /usr/etc/environment
echo "MUTTER_DEBUG_FORCE_EGL_STREAM=1" >> /usr/etc/environment

# Logo / branding stuff
rm -v /usr/share/pixmaps/fedora_whitelogo.svg
