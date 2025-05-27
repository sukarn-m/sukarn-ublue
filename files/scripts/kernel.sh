#!/usr/bin/bash

## Reference: https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh

# Enable strict error handling: exit on any error, undefined variables, or pipe failures
set -eou pipefail

# Extract current kernel version (remove "kernel-" prefix)
KERNEL_PRE="$(rpm -q kernel | sed 's/^kernel-//')"
# Get current Fedora version number
FEDORA_VERSION="$(rpm -E %fedora)"
# Set CoreOS tag for gated kernel systems
COREOS_TAG="coreos-stable"
# Set NVIDIA tag
NVIDIA_TAG="nvidia" # Options: (i) "nvidia" (possibly deprecated); and (ii) "nvidia-open"

# Remove all existing kernel packages without dependency checks
# This allows for clean kernel replacement with akmods-compatible versions
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt; do
    rpm --erase $pkg --nodeps
done

# Determine which akmods repository to use based on NVIDIA presence
if [[ -f /tmp/nvidia ]]; then
  AKMODS_REPO="akmods-${NVIDIA_TAG}"
else
  AKMODS_REPO="akmods"
fi

# Determine akmods flavor based on kernel type markers
if [[ -f "/tmp/kernel-bazzite" ]]; then
  AKMODS_FLAVOR="bazzite"
elif [[ -f "/tmp/kernel-gated" ]]; then
  AKMODS_FLAVOR="${COREOS_TAG}"
else
  AKMODS_FLAVOR="main"
fi

# Handle special case: both gated and bazzite kernel markers present
# This requires matching kernel versions between repositories
if [[ -f "/tmp/kernel-gated" && -f "/tmp/kernel-bazzite" ]]; then
  # Get the latest CoreOS kernel version from the repository
  GATED_KERNEL_VERSION="$(skopeo list-tags --retry-times 3 docker://ghcr.io/ublue-os/${AKMODS_REPO} | grep ${COREOS_TAG}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '-' -f 4)"
  # Find matching Bazzite tag with the same kernel version
  RETRIEVAL_TAG="$(skopeo list-tags --retry-times 3 docker://ghcr.io/ublue-os/${AKMODS_REPO} | grep ${AKMODS_FLAVOR}-${FEDORA_VERSION} | grep ${GATED_KERNEL_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
# Handle Bazzite kernel only
elif [[ -f "/tmp/kernel-bazzite" ]]; then
  # Get the latest Bazzite akmods tag for current Fedora version
  RETRIEVAL_TAG="$(skopeo list-tags --retry-times 3 docker://ghcr.io/ublue-os/${AKMODS_REPO} | grep ${AKMODS_FLAVOR}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
# Handle standard/main kernel
else
  # Use simple tag format for main kernel flavor
  RETRIEVAL_TAG="${AKMODS_FLAVOR}-${FEDORA_VERSION}"
fi

# Save the determined tag for debugging/logging purposes
echo "${RETRIEVAL_TAG}" > /tmp/kernel_tag

# Download akmods container image and extract RPM packages
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${RETRIEVAL_TAG}" dir:/tmp/akmods
# Extract the layer digest from the manifest
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
# Extract the compressed layer containing RPM and kernel packages
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
# Move extracted RPMs to akmods directory
mv /tmp/rpms/* /tmp/akmods/

# Handle NVIDIA-specific package extraction
if [[ -f "/tmp/nvidia" ]]; then
  # Clean up any existing kernel RPMs
  rm -rfv /tmp/kernel-rpms
  # Download NVIDIA akmods separately (may contain additional packages)
  skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/${AKMODS_REPO}:"${RETRIEVAL_TAG}" dir:/tmp/akmods-rpms
  # Extract NVIDIA akmods layer
  AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
  tar -xvzf /tmp/akmods-rpms/"$AKMODS_TARGZ" -C /tmp/
  # Move NVIDIA RPMs to separate directory
  mv /tmp/rpms/* /tmp/akmods-rpms/
fi

# Install new kernel packages
dnf5 -y install /tmp/kernel-rpms/*.rpm

# Install gaming controller support modules
# xone: Xbox One controller USB/RF driver
# xpadneo: Xbox One controller Bluetooth driver
dnf5 -y install \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*xpadneo*.rpm

# Install RPMFusion-dependent kernel modules
# First, add RPMFusion repositories (needed for v4l2loopback dependencies)
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${FEDORA_VERSION}".noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${FEDORA_VERSION}".noarch.rpm
# Install v4l2loopback: creates virtual video devices for applications like OBS
dnf5 -y install \
    v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm
# Remove RPMFusion repositories after installation to avoid conflicts
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

# Handle NVIDIA driver installation
if [[ -f "/tmp/nvidia" ]]; then
  # Exclude golang NVIDIA container toolkit to prevent conflicts
  dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit
#  # Download and make NVIDIA installation script executable
#  curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh
#  chmod +x /tmp/nvidia-install.sh
#  # Run NVIDIA installer with Silverblue configuration
#  IMAGE_NAME="silverblue" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
  # Remove conflicting nouveau (open-source NVIDIA) driver files
  rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
  # Create symbolic link for NVIDIA ML library compatibility
  ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
fi

# Check if kernel version changed during installation
KERNEL_POST="$(rpm -q kernel | sed 's/^kernel-//')"
if [[ "$KERNEL_PRE" != "$KERNEL_POST" ]]; then
    # Clean up old kernel files to save space
    rm -rf "/usr/lib/modules/${KERNEL_PRE}"
    rm -rf "/usr/share/doc/kernel-keys/${KERNEL_PRE}"
    rm -rf "/usr/src/kernels/${KERNEL_PRE}"
    # Install the correct kernel-tools version if kernel-tools is already installed
    if rpm -q kernel-tools &>/dev/null; then
      NEW_KERNEL_VERSION="$(rpm -q kernel | cut -d'-' -f2)"
      dnf5 downgrade --assumeyes "kernel-tools-${NEW_KERNEL_VERSION}"
    else
      dnf5 install --assumeyes "kernel-tools-${NEW_KERNEL_VERSION}"
    fi
fi

# Lock kernel packages to prevent automatic updates
# This prevents kernel updates from breaking akmods compatibility
dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-tools
