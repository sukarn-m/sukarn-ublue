#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# Nvidia specific Gnome flickering / tearing fix
echo "# Gnome flickering / tearing fix" >> /usr/etc/environment
echo "MUTTER_DEBUG_FORCE_EGL_STREAM=1" >> /usr/etc/environment
