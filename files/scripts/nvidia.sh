#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# Nvidia specific Gnome fixes
echo "## Required for use of OBS-VkCapture in X11 environments" >> /etc/environment
echo "## Nvidia users must additionally have nvidia-drm.modeset=1 in their kargs" >> /etc/environment
echo "# OBS_USE_EGL=1" >> /etc/environment
echo "" >> /etc/environment
echo "## Required for GNOME VRR MR" >> /etc/environment
echo "# MUTTER_DEBUG_FORCE_KMS_MODE=simple" >> /etc/environment
echo "" >> /etc/environment
echo "## Gnome flickering / tearing fix" >> /etc/environment
echo "# MUTTER_DEBUG_FORCE_EGL_STREAM=1" >> /etc/environment
