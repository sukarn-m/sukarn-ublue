#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# # Nvidia specific Gnome fixes
# echo "## Required for use of OBS-VkCapture in X11 environments" >> /etc/environment
# echo "## Nvidia users must additionally have nvidia-drm.modeset=1 in their kargs" >> /etc/environment
# echo "# OBS_USE_EGL=1" >> /etc/environment
# echo "" >> /etc/environment
# echo "## Required for GNOME VRR MR" >> /etc/environment
# echo "# MUTTER_DEBUG_FORCE_KMS_MODE=simple" >> /etc/environment
# echo "" >> /etc/environment
# echo "## Gnome flickering / tearing fix" >> /etc/environment
# echo "# MUTTER_DEBUG_FORCE_EGL_STREAM=1" >> /etc/environment

## References:
## - https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh
## - https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh

# KERNEL="$(rpm -q kernel | sed 's/^kernel-//')"
FEDORA_VERSION="$(rpm -E %fedora)"

RETRIEVAL_TAG="$(cat /tmp/kernel_tag)"

if [ -f /tmp/coreos_kernel ]; then
  AKMODS_TYPE="coreos-stable"
else
  AKMODS_TYPE="main" # The 'bazzite' variant does not have Fedora 40 releases.
fi

skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia:"${RETRIEVAL_TAG}" dir:/tmp/akmods-rpms
NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods-rpms/

curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh # Change when nvidia-install.sh updates
chmod +x /tmp/nvidia-install.sh
IMAGE_NAME="silverblue" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
