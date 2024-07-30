#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

chmod 0700 /usr/bin/nvidia-kargs

# Nvidia specific Gnome fixes
echo "## Required for use of OBS-VkCapture in X11 environments" >> /usr/etc/environment
echo "## Nvidia users must additionally have nvidia-drm.modeset=1 in their kargs" >> /usr/etc/environment
echo "# OBS_USE_EGL=1" >> /usr/etc/environment
echo ""
echo "## Required for GNOME VRR MR" >> /usr/etc/environment
echo "MUTTER_DEBUG_FORCE_KMS_MODE=simple" >> /usr/etc/environment
echo "" >> /usr/etc/environment
echo "## Gnome flickering / tearing fix" >> /usr/etc/environment
echo "# MUTTER_DEBUG_FORCE_EGL_STREAM=1" >> /usr/etc/environment
