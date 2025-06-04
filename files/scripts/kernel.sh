#!/usr/bin/bash

## Initial reference: https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh
## Heavily modified from that starting point.

## Untested:
## - "nvidia-open"
## Currently fails for:
## - bazzite-latest if the current OS is on the GTS track. Example: current OS F41, bazzite-latest: F42

# Enable strict error handling: exit on any error, undefined variables, or pipe failures
set -eou pipefail

# ----------------- Configs -----------------

function user_config () {
  PREFERENCE_ORDER=("bazzite-gated" "bazzite" "gated" "bazzite-latest" "standard") # Options: Whatever tags are available on the repositories used. See the variables COREOS_TAG, NVIDIA_TAG, AKMODS_FLAVOUR and the function get_tags. The script will try to get akmods, kernel and nvidia drivers in this decreasing order of preference. If you're on the latest fedora release, then "bazzite" and "bazzite-latest" do the same thing. If you're on an older fedora release, such as Universal Blue's GTS track, then "bazzite-latest" is likely to fail.
  BAZZITE_ONLY="0"
  NVIDIA_HOSTNAMES=("") # Hostnames defined here will get nvidia drivers. Set the hostname in /etc/hostname or create /tmp/nvidia before running this script if you want nvidia drivers. The script first checks for presence of the file /tmp/nvidia. If /tmp/nvidia is found, it will use nvidia drivers. If that file is not found, it will check for a match of hostnames listed here.
  
  NVIDIA_TAG="nvidia" # Options: (i) "nvidia"; and (ii) "nvidia-open". The option for "nvidia-open" hasn't been tested yet. Currently has incomplete nvidia handling. "nvidia-open" is untested.
  COREOS_TAG="coreos-stable" # Set CoreOS tag for gated kernel systems
  KERNEL_PRE="$(rpm -q kernel | sed 's/^kernel-//')" # Extract current kernel version (remove "kernel-" prefix)
  FEDORA_VERSION="$(rpm -E %fedora)" # Get current Fedora version number
  IMAGE_NAME="" # Options: (i) ""; (ii) "silverblue"; (iii) "kinoite"; and (iv) "sericea". Affects additional package installation for nvidia variants. See VARIANT_PACKAGES in the function install_nvidia_packages
  AKMODS_TAGS="/tmp/akmods-tags.txt"
  AKMODS_NVIDIA_TAGS="/tmp/akmods-nvidia-tags.txt"
  
  VARIANTS_TRIED=()
}

function initial_config () {
  if [[ -f "/tmp/nvidia" ]]; then
    NVIDIA_WANTED="1"
    remove /tmp/nvidia
  else
    NVIDIA_WANTED="0"
  fi
  
  local current_hostname=""
  local actual_hostname="$(hostnamectl hostname)"
  for current_hostname in ${NVIDIA_HOSTNAMES[@]}; do
    if [[ "$actual_hostname" == "$current_hostname" ]]; then
      NVIDIA_WANTED="1"
    fi
  done
  
  local option=""
  if [[ $BAZZITE_ONLY == "0" ]]; then
    VARIANT_CURRENT="${PREFERENCE_ORDER[0]}"
  elif [[ $BAZZITE_ONLY == "1" ]]; then
    for option in ${PREFERENCE_ORDER[@]}; do
      if [[ $option =~ "bazzite" ]]; then
        VARIANT_CURRENT="$option"
        break
      fi
    done
  else
    echo "ERROR: Variable BAZZITE_ONLY does not match 0 or 1"
  fi
}

function reset_vars () {
  # In case of gated+bazzite, if there's no matching bazzite kernel for the latest coreos kernel version, should we fall back to using the latest bazzite for the current os, or use the gated kernel?
  KERNEL_FINDING_SUCCESS="0"

  # Determine akmods flavor based on kernel type markers
  if [[ $VARIANT_CURRENT =~ "bazzite" ]]; then
    AKMODS_FLAVOUR="bazzite"
  elif [[ $VARIANT_CURRENT =~ "gated" ]]; then
    AKMODS_FLAVOUR="${COREOS_TAG}"
  else
    AKMODS_FLAVOUR="main"
  fi
}

# ----------------- Retrieval -----------------

function get_tags () {
  local akmods_repo = "ghcr.io/ublue-os/akmods"
  skopeo list-tags --retry-times 3 docker://${akmods_repo} > ${AKMODS_TAGS}
  if [[ $NVIDIA_WANTED == "1" ]]; then
    skopeo list-tags --retry-times 3 docker://${akmods_repo}-${NVIDIA_TAG} > ${AKMODS_NVIDIA_TAGS}
  fi
}

function confirm_nvidia () {
  if [[ $NVIDIA_WANTED == "0" ]] || $(cat ${AKMODS_NVIDIA_TAGS} | grep -q ${RETRIEVAL_TAG}); then
    KERNEL_FINDING_SUCCESS="1"
    VARIANT_USED="${VARIANT_CURRENT}"
  else
    set_next_variant
  fi
}

function try_bazzite_latest () {
  if [[ $KERNEL_FINDING_SUCCESS == "0" ]] && [[ $VARIANT_CURRENT == "bazzite-latest" ]]; then
    RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR} | sort -r | head -n 1 | cut -d '"' -f 2)"
    confirm_nvidia
  fi
}

function try_bazzite_gated () {
  # Handle special case: both gated and bazzite kernel markers present
  # This requires matching kernel versions between repositories
  if [[ $KERNEL_FINDING_SUCCESS == "0" ]] && [[ $VARIANT_CURRENT == "bazzite-gated" ]]; then
    # Get the latest CoreOS kernel version from the repository
    GATED_KERNEL_VERSION="$(cat ${AKMODS_TAGS} | grep ${COREOS_TAG}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '-' -f 4)"
    # Find matching Bazzite tag with the same kernel version
    if $(cat ${AKMODS_TAGS} | grep ${AKMODS-FLAVOUR}-${FEDORA_VERSION} | grep -q ${GATED_KERNEL_VERSION}); then
      RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR}-${FEDORA_VERSION} | grep ${GATED_KERNEL_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
      confirm_nvidia
    else
      echo "ERROR: Failed to match bazzite and gated tags."
      set_next_variant
    fi
  fi
}

function try_bazzite () {
  if [[ ${KERNEL_FINDING_SUCCESS} == "0" ]] && [[ $VARIANT_CURRENT == "bazzite" ]]; then
    RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
    confirm_nvidia
  fi
}

function try_gated () {
  if [[ ${KERNEL_FINDING_SUCCESS} == "0" ]] && [[ $VARIANT_CURRENT == "gated" ]]; then
    RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
    confirm_nvidia
  fi
}

function try_standard () {
  # Handle standard/main kernel
  if [[ ${KERNEL_FINDING_SUCCESS} == "0" ]] && [[ $VARIANT_CURRENT == "standard" ]]; then
    RETRIEVAL_TAG="${AKMODS_FLAVOUR}-${FEDORA_VERSION}"
    confirm_nvidia
  fi
}

function set_retrieval_tag () {
  try_bazzite_gated
  try_bazzite_latest
  try_bazzite
  try_gated
  try_standard
  if [[ ${KERNEL_FINDING_SUCCESS} == "0" ]]; then
    set_next_variant
    set_retrieval_tag
  fi
}

function set_next_variant () {
  local option=""
  local variant=""
  local match_found="false"

  VARIANTS_TRIED+=("${VARIANT_CURRENT}")
  echo "Tried so far: ${VARIANTS_TRIED[@]}"

  for option in ${PREFERENCE_ORDER[@]}; do
    local already_tried="false"
    for variant in ${VARIANTS_TRIED[@]}; do
      if [[ "${option}" == "${variant}" ]]; then
        already_tried="true"
        break
      fi
    done
    if [[ "$already_tried" == "false" ]]; then
      if [[ $BAZZITE_ONLY == "0" ]]; then
        VARIANT_CURRENT="${option}"
        echo "Trying next: ${VARIANT_CURRENT}"
        match_found="true"
        break
      else break
      fi
    fi
  done
  if [[ "$match_found" == "false" ]]; then
    echo "ERROR: We've tried all options. Nothing left to try. No working tag found."
    exit 1
  fi
}

function download_normal_packages () {
  # Download akmods container image and extract RPM packages
  skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${RETRIEVAL_TAG}" dir:/tmp/akmods
  # Extract the layer digest from the manifest
  AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
  # Extract the compressed layer containing RPM and kernel packages
  tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
  # Move extracted RPMs to akmods directory
  mv /tmp/rpms/* /tmp/akmods/
}

function download_nvidia_packages () {
  # Handle NVIDIA-specific package extraction
  if [[ $NVIDIA_WANTED == "1" ]]; then
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
}

# ----------------- Sanity Checks -----------------

function initial_sanity_check () {
  if [[ ! $(command -v dnf5) ]]; then
    echo "Requires dnf5... Exiting"
    exit 1
  fi
}

function nvidia_sanity_check () {
  if [[ $NVIDIA_WANTED == "1" ]]; then
    if ! dnf5 list installed ublue-os-nvidia-addons &>/dev/null; then
      nvidia_initial_setup
    fi

    source /tmp/akmods-rpms/kmods/nvidia-vars
    
    VERSION="$(rpm -q /tmp/akmods-rpms/kmods/kmod-nvidia-*.rpm | sed 's/^kmod-nvidia-//' | sed 's/\.[^.]*$//')"

    LOCAL_NVIDIA_PKG="/tmp/akmods-rpms/kmods/kmod-nvidia-${KERNEL_VERSION}-${NVIDIA_AKMOD_VERSION}.fc*.rpm"

    NVIDIA_PKGS=(
      "libnvidia-fbc-${VERSION}.x86_64"
      "libnvidia-ml-${VERSION}.i686"
      "libva-nvidia-driver"
      "nvidia-driver-${VERSION}.x86_64"
      "nvidia-driver-cuda-${VERSION}.x86_64"
      "nvidia-driver-cuda-libs-${VERSION}.i686"
      "nvidia-driver-libs-${VERSION}.i686"
      "nvidia-settings-${VERSION}.x86_64"
      "nvidia-container-toolkit"
    )

    NVIDIA_PKGS_FOUND_ALL="1"

    for pkg in "${NVIDIA_PKGS[@]}"; do
      if ! dnf5 info "$pkg" &>/dev/null; then
        echo "ERROR: Package not found: $pkg"
        NVIDIA_PKGS_FOUND_ALL="0"
        break
      fi
    done

#    if [[ ! -f "${LOCAL_NVIDIA_PKG}" ]]; then
#      echo "Local RPM version mismatch."
#      echo "Expected to find file ${LOCAL_NVIDIA_PKG}"
#      echo "Actually found the following:"
#      echo "$(ls /tmp/akmods-rpms/kmods/)"
#      NVIDIA_PKGS_FOUND_ALL="0"
#    fi
    
    if [[ ${NVIDIA_PKGS_FOUND_ALL} == "0" ]]; then
      echo "ERROR: nVidia version mismatch."
      echo "The version of kmod available locally: ${VERSION}"
      echo "The version of packages available on the repository:"
      echo "$(dnf5 list --showduplicates nvidia-driver)"
      echo "We had tried ${VARIANT_USED}."
      set_next_variant
      get_and_check
    fi
  fi
}

# ----------------- Installation & Cleanup -----------------

function rpm_erase () {
  # Remove all existing kernel packages without dependency checks
  # This allows for clean kernel replacement with akmods-compatible versions
  for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt; do
      rpm --erase $pkg --nodeps
  done
}

function list_packages () {
  tree /tmp/akmods/kmods
  tree /tmp/akmods/ublue-os
  tree /tmp/kernel-rpms
  if [[ $NVIDIA_WANTED == "1" ]]; then
    tree /tmp/akmods-rpms/kmods
  fi
}

function install_packages () {
  # Install new kernel packages
  dnf5 -y install /tmp/kernel-rpms/*.rpm
  
  # Install gaming controller support modules
  # xone: Xbox One controller USB/RF driver
  dnf5 -y install /tmp/akmods/kmods/*xone*.rpm
  
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
  
  # Check if kernel version changed during installation
  KERNEL_POST="$(rpm -q kernel | sed 's/^kernel-//')"
  if [[ "$KERNEL_PRE" != "$KERNEL_POST" ]]; then
    # Install the correct kernel-tools version
    if rpm -q kernel-tools &>/dev/null; then
      NEW_KERNEL_VERSION="$(rpm -q kernel | cut -d'-' -f2)"
      dnf5 downgrade --assumeyes "kernel-tools-${NEW_KERNEL_VERSION}"
    else
      dnf5 install --assumeyes "kernel-tools-${NEW_KERNEL_VERSION}"
    fi
  fi
}

function nvidia_initial_setup () {
  if [[ $NVIDIA_WANTED == "1" ]]; then
    # disable any remaining rpmfusion repos
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/rpmfusion*.repo
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo
    
    dnf5 install -y /tmp/akmods-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm
    
    # enable repos provided by ublue-os-nvidia-addons
    sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/negativo17-fedora-nvidia.repo
    sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/nvidia-container-toolkit.repo
    
    # Install MULTILIB packages from negativo17-multimedia prior to disabling repo
    MULTILIB=(
        mesa-dri-drivers.i686
        mesa-filesystem.i686
        mesa-libEGL.i686
        mesa-libGL.i686
        mesa-libgbm.i686
        mesa-va-drivers.i686
        mesa-vulkan-drivers.i686
    )
    
    if [[ "$(rpm -E %fedora)" -lt 41 ]]; then
        MULTILIB+=(
            mesa-libglapi.i686
            libvdpau.i686
        )
    fi
    
    dnf5 install -y "${MULTILIB[@]}"
    
    # Disable Multimedia
    NEGATIVO17_MULT_PREV_ENABLED=N
    if [[ -f /etc/yum.repos.d/negativo17-fedora-multimedia.repo ]] && grep -q "enabled=1" /etc/yum.repos.d/negativo17-fedora-multimedia.repo; then
      NEGATIVO17_MULT_PREV_ENABLED=Y
      echo "disabling negativo17-fedora-multimedia to ensure negativo17-fedora-nvidia is used"
      sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo
    fi
    
    # Enable staging for supergfxctl if repo file exists
    if [[ -f /etc/yum.repos.d/_copr_ublue-os-staging.repo ]]; then
      sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-staging.repo
    else
      # Otherwise, retrieve the repo file for staging
      curl -Lo /etc/yum.repos.d/_copr_ublue-os-staging.repo https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_VERSION}"/ublue-os-staging-fedora-"${FEDORA_VERSION}".repo
    fi
  fi
}

function install_nvidia_packages () {
  if [[ $NVIDIA_WANTED == "1" ]]; then
    # Exclude golang NVIDIA container toolkit to prevent conflicts
    dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit
    # Remove conflicting nouveau (open-source NVIDIA) driver files
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
    # Create symbolic link for NVIDIA ML library compatibility
    ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
    
    if [[ "${IMAGE_NAME}" == "kinoite" ]]; then
        VARIANT_PKGS="supergfxctl-plasmoid supergfxctl"
    elif [[ "${IMAGE_NAME}" == "silverblue" ]]; then
        VARIANT_PKGS="gnome-shell-extension-supergfxctl-gex supergfxctl"
    else
        VARIANT_PKGS=""
    fi
    
    dnf5 install -y ${NVIDIA_PKGS[@]} ${VARIANT_PKGS} ${LOCAL_NVIDIA_PKG}
    
    ## nvidia post-install steps
    # disable repos provided by ublue-os-nvidia-addons
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-nvidia.repo
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/nvidia-container-toolkit.repo
    
    # Disable staging
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-staging.repo
    
    # ensure kernel.conf matches NVIDIA_FLAVOR (which must be nvidia or nvidia-open)
    # kmod-nvidia-common defaults to 'nvidia-open' but this will match our akmod image
    sed -i "s/^MODULE_VARIANT=.*/MODULE_VARIANT=${NVIDIA_TAG}/" /etc/nvidia/kernel.conf
    
    systemctl enable ublue-nvctk-cdi.service
    semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp
    
    # Universal Blue specific Initramfs fixes
    cp /etc/modprobe.d/nvidia-modeset.conf /usr/lib/modprobe.d/nvidia-modeset.conf
    # we must force driver load to fix black screen on boot for nvidia desktops
    sed -i 's@omit_drivers@force_drivers@g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
    # as we need forced load, also mustpre-load intel/amd iGPU else chromium web browsers fail to use hardware acceleration
    sed -i 's@ nvidia @ i915 amdgpu nvidia @g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
    
    if [[ "${IMAGE_NAME}" == "sericea" ]]; then
        mv /etc/sway/environment{,.orig}
        install -Dm644 /usr/share/ublue-os/etc/sway/environment /etc/sway/environment
    fi
    
    # re-enable negativo17-mutlimedia since we disabled it
    if [[ "${NEGATIVO17_MULT_PREV_ENABLED}" = "Y" ]]; then
        sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/negativo17-fedora-multimedia.repo
    fi
  fi
}

function remove () {
  if [[ -d "$1" ]] || [[ -f "$1" ]] ; then
    rm -rf "$1"
  fi
}

function initial_cleanup () {
  remove /tmp/akmods
  remove /tmp/akmods-rpms
  remove /tmp/kernel-rpms
}

function final_cleanup () {
  initial_cleanup
  if [[ "$KERNEL_PRE" != "$KERNEL_POST" ]]; then
    # Clean up old kernel files to save space
    remove "/usr/lib/modules/${KERNEL_PRE}"
    remove "/usr/share/doc/kernel-keys/${KERNEL_PRE}"
    remove "/usr/src/kernels/${KERNEL_PRE}"
  fi
}

function lock_version () {
  # Lock kernel packages to prevent automatic updates
  # This prevents kernel updates from breaking akmods compatibility
  dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-tools
}

# ----------------- Main script logic -----------------

function get_and_check () {
  reset_vars
  initial_cleanup
  set_retrieval_tag
  download_normal_packages
  download_nvidia_packages
  nvidia_sanity_check
}

function main () {
  user_config
  initial_config
  initial_sanity_check
  reset_vars
  get_tags
  get_and_check
  rpm_erase
  list_packages
  install_packages
  install_nvidia_packages
  final_cleanup
  lock_version
}

main
