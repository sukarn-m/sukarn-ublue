#!/usr/bin/bash

## Initial reference: https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh
## Heavily modified from that starting point.

# Enable strict error handling: exit on any error, undefined variables, or pipe failures
set -eou pipefail

# In case of gated+bazzite, if there's no matching bazzite kernel for the latest coreos kernel version, should we fall back to using the latest bazzite for the current os, or use the gated kernel?
GATED_BAZZITE_FALLBACK="bazzite-matching-fedora" # Options: (i) "bazzite-matching-fedora"; (ii) "bazzite-latest"; and (iii) "gated"

# Set NVIDIA tag. Currently has incomplete nvidia handling. "nvidia-open" is entirely untested. "nvidia" may lead to non-matching tags, erroring out in the script instead of being gracefully handled.
NVIDIA_TAG="nvidia" # Options: (i) "nvidia"; and (ii) "nvidia-open". The option for "nvidia-open" hasn't been tested yet.
# Set CoreOS tag for gated kernel systems
COREOS_TAG="coreos-stable"
# Extract current kernel version (remove "kernel-" prefix)
KERNEL_PRE="$(rpm -q kernel | sed 's/^kernel-//')"
# Get current Fedora version number
FEDORA_VERSION="$(rpm -E %fedora)"

AKMODS_TAGS="/tmp/akmods-tags.txt"
AKMODS_NVIDIA_TAGS="/tmp/akmods-nvidia-tags.txt"
KERNEL_FINDING_SUCCESS="0"

# Determine which akmods repository to use based on NVIDIA presence
if [[ -f /tmp/nvidia ]]; then
  AKMODS_REPO="akmods-${NVIDIA_TAG}"
else
  AKMODS_REPO="akmods"
fi

# Determine akmods flavor based on kernel type markers
if [[ -f "/tmp/kernel-bazzite" ]]; then
  AKMODS_FLAVOUR="bazzite"
elif [[ -f "/tmp/kernel-gated" ]]; then
  AKMODS_FLAVOUR="${COREOS_TAG}"
else
  AKMODS_FLAVOUR="main"
fi

skopeo list-tags --retry-times 3 docker://ghcr.io/ublue-os/akmods > ${AKMODS_TAGS}
if [[ -f "/tmp/nvidia" ]]; then
  skopeo list-tags --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia > ${AKMODS_NVIDIA_TAGS}
fi

# Handle special case: both gated and bazzite kernel markers present
# This requires matching kernel versions between repositories
if [[ -f "/tmp/kernel-gated" && -f "/tmp/kernel-bazzite" ]]; then
  # Get the latest CoreOS kernel version from the repository
  GATED_KERNEL_VERSION="$(cat ${AKMODS_TAGS} | grep ${COREOS_TAG}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '-' -f 4)"
  # Find matching Bazzite tag with the same kernel version
  if cat ${AKMODS_TAGS} | grep ${AKMODS-FLAVOUR}-${FEDORA_VERSION} | grep ${GATED_KERNEL_VERSION}; then
    RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR}-${FEDORA_VERSION} | grep ${GATED_KERNEL_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
    if [[ ! -f "/tmp/nvidia" ]] || cat ${AKMODS_NVIDIA_TAGS} | grep ${RETRIEVAL_TAG}; then
      KERNEL_FINDING_SUCCESS="1"
    fi
  elif [[ ${GATED_BAZZITE_FALLBACK} == "bazzite-matching-fedora" ]]; then
    echo "Falling back to latest bazzite kernel for the current OS."
    rm /tmp/kernel-gated
  elif [[ ${GATED_BAZZITE_FALLBACK} == "bazzite-latest" ]]; then
    echo "Falling back to latest bazzite kernel, ignoring current OS version."
    BAZZITE_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR} | sort -r | head -n 1 | cut -d '"' -f 2)"
    if [[ ! -f "/tmp/nvidia" ]]; then
      RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR} | sort -r | head -n 1 | cut -d '"' -f 2)"
      KERNEL_FINDING_SUCCESS="1"
    elif cat ${AKMODS_NVIDIA_TAGS} | grep ${BAZZITE_TAG}; then
      RETRIEVAL_TAG="${BAZZITE_TAG}"
      KERNEL_FINDING_SUCCESS="1"
    fi
  elif [[ ${GATED_BAZZITE_FALLBACK} == "gated" ]]; then
    echo "Falling back to gated kernel."
    rm /tmp/kernel-bazzite
  else
    echo "No fallback option defined. Will fall back to main kernel."
  fi
fi

# Handle Bazzite kernel (non-gated)
if [[ ${KERNEL_FINDING_SUCCESS} == "0" ]]; then
  if [[ -f "/tmp/kernel-bazzite" ]]; then
    RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
    if [[ ! -f "/tmp/nvidia" ]] || cat ${AKMODS_NVIDIA_TAGS} | grep ${RETRIEVAL_TAG}; then
      KERNEL_FINDING_SUCCESS="1"
    fi
  fi
fi

# Handle standard/main kernel
if [[ ${KERNEL_FINDING_SUCCESS} == "0" ]]; then
  # Use simple tag format for main kernel flavor or final fallback option
  RETRIEVAL_TAG="${AKMODS_FLAVOUR}-${FEDORA_VERSION}"
  if [[ ! -f "/tmp/nvidia" ]] || cat ${AKMODS_NVIDIA_TAGS} | grep ${RETRIEVAL_TAG}; then
    KERNEL_FINDING_SUCCESS="1"
  fi
fi

if [[ ${KERNEL_FINDING_SUCCESS} == "0" ]]; then
  echo "ERROR: Failed to find an appropriate akmods/kernel/nvidia tag."
  exit 1
fi

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
  # Clean up existing kernel RPMs from the akmods download above
  rm -rfv /tmp/kernel-rpms
  # Download NVIDIA akmods + kernel build
  skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia:"${RETRIEVAL_TAG}" dir:/tmp/akmods-rpms
  # Extract NVIDIA akmods layer
  AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
  tar -xvzf /tmp/akmods-rpms/"$AKMODS_TARGZ" -C /tmp/
  # Move NVIDIA RPMs to separate directory
  mv /tmp/rpms/* /tmp/akmods-rpms/
fi

# ----------------- End determination and retrieval ----------------

# Remove all existing kernel packages without dependency checks
# This allows for clean kernel replacement with akmods-compatible versions
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt; do
    rpm --erase $pkg --nodeps
done

# Install new kernel packages
dnf5 -y install /tmp/kernel-rpms/*.rpm

# Install gaming controller support modules
# xone: Xbox One controller USB/RF driver
# xpadneo: Xbox One controller Bluetooth driver
dnf5 -y install /tmp/akmods/kmods/*xone*.rpm || true
dnf5 -y install /tmp/akmods/kmods/*xpadneo*.rpm || true

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

# Handle NVIDIA driver stuff. Actual nvidia installation is handled by a separate script.
if [[ -f "/tmp/nvidia" ]]; then
  # Exclude golang NVIDIA container toolkit to prevent conflicts
  dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit
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
