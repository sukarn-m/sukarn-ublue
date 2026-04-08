#!/usr/bin/bash

## Initial reference:
## - https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh
## - https://github.com/ublue-os/main/blob/main/build_files/nvidia-install.sh
## Heavily modified from that starting point.

# Enable strict error handling: exit on any error, undefined variables, or pipe failures
set -eou pipefail

# ----------------- Configs -----------------

function user_config () {
  PREFERENCE_ORDER=("gated" "main" "bazzite" "bazzite-gated") # Options: Whatever tags are available on the repositories used. Special cases: (i) "bazzite-gated" fetches the tag from "coreos-stable" and then tries to get a matching tag of "bazzite"; (ii) "gated" is mapped to "coreos-stable". See the variables GATED_TAG, NVIDIA_TAG, AKMODS_FLAVOUR and the function get_tags. The script will try to get akmods, kernel and nvidia drivers in this decreasing order of preference.
  BAZZITE_ONLY_HOSTNAMES=() # Hostnames defined here will get only the bazzite kernel, and the script will filter out any tags from the PREFERENCE_ORDER that do not contain "bazzite". Set the hostname in /etc/hostname or create /tmp/bazzite-only before running this script if you want to filter out non-bazzite tags. The script first checks for the presence of the file /tmp/bazzite-only.
  NVIDIA_HOSTNAMES=() # Hostnames defined here will get nvidia drivers. Set the hostname in /etc/hostname or create /tmp/nvidia before running this script if you want nvidia drivers. The script first checks for presence of the file /tmp/nvidia. If /tmp/nvidia is found, it will use nvidia drivers. If that file is not found, it will check for a match of hostnames listed here.
#  AKMODS_WANTED=("xone" "v4l2loopback") # Options: Only the akmods provided in the ublue akmods releases. If unsure, run this script once. It outputs a list of all the akmods packages that are found.
  AKMODS_WANTED=() # Options: Only the akmods provided in the ublue akmods releases. If unsure, run this script once. It outputs a list of all the akmods packages that are found.
  NVIDIA_TAG="nvidia-open" # Options: (i) "nvidia"; and (ii) "nvidia-open".
  IMAGE_NAME="" # Options: (i) ""; (ii) "silverblue"; (iii) "kinoite"; and (iv) "sericea". Affects additional package installation for nvidia variants. See VARIANT_PACKAGES in the function install_nvidia_packages
  GATED_TAG="coreos-stable" # Options: Preferably use "coreos-stable" or "coreos-testing". Used for gated kernel systems.
}

function initial_config () {
  KERNEL_PRE="$(rpm -q kernel | sed 's/^kernel-//')" # Extract current kernel version (remove "kernel-" prefix)
  FEDORA_VERSION="$(rpm -E %fedora)" # Get current Fedora version number
  SECURE_TMP_DIR=$(mktemp -d)
  trap 'rm -rf "${SECURE_TMP_DIR}"' EXIT
  AKMODS_TAGS="${SECURE_TMP_DIR}/akmods-tags.txt" # Stores the tags list so that they aren't repeatedly checked on the repository
  AKMODS_NVIDIA_TAGS="${SECURE_TMP_DIR}/akmods-nvidia-tags.txt" # Stores the tags list so that they aren't repeatedly checked on the repository
  VARIANTS_TRIED=()
  AKMODS_REPO="ghcr.io/ublue-os/akmods"

  echo "FEDORA_VERSION=${FEDORA_VERSION}"

  # Logic for NVIDIA_WANTED
  NVIDIA_WANTED="0"
  if [[ -f "/tmp/nvidia" ]]; then
    NVIDIA_WANTED="1"
    remove /tmp/nvidia
  elif [[ ${#NVIDIA_HOSTNAMES[@]} -gt 0 ]]; then
    local current_hostname=""
    local actual_hostname="$(hostnamectl hostname)"
    for current_hostname in ${NVIDIA_HOSTNAMES[@]}; do
      if [[ "$actual_hostname" == "$current_hostname" ]]; then
        NVIDIA_WANTED="1"
      fi
    done
  fi
  
  # Logic for BAZZITE_ONLY
  BAZZITE_ONLY="0"
  if [[ -f "/tmp/bazzite-only" ]]; then
    BAZZITE_ONLY="1"
    remove /tmp/bazzite-only
  elif [[ ${#BAZZITE_ONLY_HOSTNAMES[@]} -gt 0 ]]; then
    local current_hostname=""
    local actual_hostname="$(hostnamectl hostname)"
    for current_hostname in ${BAZZITE_ONLY_HOSTNAMES[@]}; do
      if [[ "$actual_hostname" == "$current_hostname" ]]; then
        BAZZITE_ONLY="1"
      fi
    done
  fi

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
  KERNEL_FINDING_SUCCESS="0"

  if [[ $VARIANT_CURRENT =~ "bazzite" ]]; then
    AKMODS_FLAVOUR="bazzite"
  elif [[ $VARIANT_CURRENT =~ "gated" ]]; then
    AKMODS_FLAVOUR="${GATED_TAG}"
  else
    AKMODS_FLAVOUR="main"
  fi
}

# ----------------- Retrieval -----------------

function get_tags () {
  if ! skopeo list-tags --retry-times 3 docker://${AKMODS_REPO} > "${AKMODS_TAGS}"; then
    echo "ERROR: Failed to fetch tags from ${AKMODS_REPO}"
    exit 1
  fi
  if [[ $NVIDIA_WANTED == "1" ]]; then
    if ! skopeo list-tags --retry-times 3 docker://${AKMODS_REPO}-${NVIDIA_TAG} > "${AKMODS_NVIDIA_TAGS}"; then
      echo "ERROR: Failed to fetch NVIDIA tags from ${AKMODS_REPO}-${NVIDIA_TAG}"
      exit 1
    fi
  fi
}

function confirm_tag () {
  if [[ $NVIDIA_WANTED == "0" ]] || grep -q "${RETRIEVAL_TAG}" "${AKMODS_NVIDIA_TAGS}"; then
    KERNEL_FINDING_SUCCESS="1"
    VARIANT_USED="${VARIANT_CURRENT}"
  fi
}

function try_bazzite_gated () {
  # Get the latest CoreOS kernel version from the repository
#  GATED_KERNEL_VERSION="$(cat ${AKMODS_TAGS} | grep ${GATED_TAG}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '-' -f 4)"
  echo "Attempting to set RETRIEVAL_TAG in try_bazzite_gated"
  GATED_KERNEL_VERSION="$(grep "${GATED_TAG}-${FEDORA_VERSION}" "${AKMODS_TAGS}" | sort -r | head -n 2 | sort | head -n 1 | cut -d '-' -f 4)"
  echo "GATED_KERNEL_VERSION=${GATED_KERNEL_VERSION}"
  # Find matching Bazzite tag with the same kernel version
  if grep "${AKMODS_FLAVOUR}-${FEDORA_VERSION}" "${AKMODS_TAGS}" | grep -q "${GATED_KERNEL_VERSION}"; then
 #   RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR}-${FEDORA_VERSION} | grep ${GATED_KERNEL_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
    RETRIEVAL_TAG="$(grep "${AKMODS_FLAVOUR}-${FEDORA_VERSION}" "${AKMODS_TAGS}" | grep "${GATED_KERNEL_VERSION}" | sort -r | head -n 2 | sort | head -n 1 | cut -d '"' -f 2)"
    confirm_tag
    echo "RETRIEVAL_TAG=${RETRIEVAL_TAG}"
  else
    echo "ERROR: Failed to find matching gated bazzite kernel tag."
  fi
}

function try_standard () {
#  RETRIEVAL_TAG="$(cat ${AKMODS_TAGS} | grep ${AKMODS_FLAVOUR}-${FEDORA_VERSION} | sort -r | head -n 1 | cut -d '"' -f 2)"
  local retrieval_tag="$(grep "${AKMODS_FLAVOUR}-${FEDORA_VERSION}" "${AKMODS_TAGS}" | sort -r | head -n 3 | sort | head -n 1 | cut -d '"' -f 2)" || true
  if [ -n "$retrieval_tag" ]; then
    RETRIEVAL_TAG="${retrieval_tag}"
    confirm_tag
    echo "RETRIEVAL_TAG=${RETRIEVAL_TAG}"
  else
    echo "Failed the if condition for $retrieval_tag"
    set_next_variant
    set_retrieval_tag
  fi
}

function set_retrieval_tag () {
  reset_vars
  if [[ $VARIANT_CURRENT == "bazzite-gated" ]]; then
    try_bazzite_gated
  else
    try_standard
  fi
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
      elif [[ $BAZZITE_ONLY == "1" ]]; then
        if [[ "${option}" =~ "bazzite" ]]; then
          VARIANT_CURRENT="${option}"
          echo "Trying next: ${VARIANT_CURRENT}"
          match_found="true"
          break
        fi
      else
        echo "ERROR: How did the script even get to this stage with BAZZITE_ONLY not set properly?"
        exit 1
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
  echo "Attempting to download tag ${RETRIEVAL_TAG}"
  skopeo copy --retry-times 3 docker://${AKMODS_REPO}:"${RETRIEVAL_TAG}" dir:"${SECURE_TMP_DIR}/akmods"
  # Extract the layer digest from the manifest
  echo "Extracting..."
  AKMODS_TARGZ=$(jq -r '.layers[].digest' <"${SECURE_TMP_DIR}/akmods/manifest.json" | cut -d : -f 2)
  if [[ -z "${AKMODS_TARGZ}" ]]; then
    echo "ERROR: Failed to extract layer digest from manifest"
    exit 1
  fi
  tar -xvzf "${SECURE_TMP_DIR}/akmods/${AKMODS_TARGZ}" -C "${SECURE_TMP_DIR}"
  echo "Moving rpms into ${SECURE_TMP_DIR}/akmods"
  if ! mv "${SECURE_TMP_DIR}/rpms/"* "${SECURE_TMP_DIR}/akmods/"; then
    echo "ERROR: No RPMs found after extraction"
    exit 1
  fi
}

function download_nvidia_packages () {
  if [[ $NVIDIA_WANTED == "1" ]]; then
    # Clean up existing kernel RPMs from the akmods download above
    echo "Replacing the kernel RPMs from akmods with the RPMs from the nvidia build."
    remove "${SECURE_TMP_DIR}/kernel-rpms"
    # Download NVIDIA akmods + kernel build
    echo "Attempting to download nvidia tag"
    skopeo copy --retry-times 3 docker://${AKMODS_REPO}-${NVIDIA_TAG}:"${RETRIEVAL_TAG}" dir:"${SECURE_TMP_DIR}/akmods-rpms"
    # Extract NVIDIA akmods layer
    echo "Extracting..."
    AKMODS_TARGZ=$(jq -r '.layers[].digest' <"${SECURE_TMP_DIR}/akmods-rpms/manifest.json" | cut -d : -f 2)
    if [[ -z "${AKMODS_TARGZ}" ]]; then
      echo "ERROR: Failed to extract NVIDIA layer digest from manifest"
      exit 1
    fi
    tar -xvzf "${SECURE_TMP_DIR}/akmods-rpms/${AKMODS_TARGZ}" -C "${SECURE_TMP_DIR}"
    if ! mv "${SECURE_TMP_DIR}/rpms/"* "${SECURE_TMP_DIR}/akmods-rpms/"; then
      echo "ERROR: No NVIDIA RPMs found after extraction"
      exit 1
    fi
  fi
}

# ----------------- Sanity Checks -----------------

function initial_sanity_check () {
  if [[ ! $(command -v dnf5) ]]; then
    echo "Requires dnf5... Exiting"
    exit 1
  fi

  if [[ ! -v PREFERENCE_ORDER || ${#PREFERENCE_ORDER[@]} -eq 0 ]]; then
    echo "ERROR: PREFERENCE_ORDER not set."
    exit 1
  fi
}

function nvidia_sanity_check () {
  if [[ $NVIDIA_WANTED == "1" ]]; then
    if ! dnf5 list installed ublue-os-nvidia-addons &>/dev/null; then
      nvidia_initial_setup
    fi

    if [[ ! -f "${SECURE_TMP_DIR}/akmods-rpms/kmods/nvidia-vars" ]]; then
      echo "ERROR: nvidia-vars not found in extracted akmods. The akmods image may be malformed."
      exit 1
    fi
    source "${SECURE_TMP_DIR}/akmods-rpms/kmods/nvidia-vars"
    
    # Extract version from rpm.
    # VERSION format example: 590.48.01-1.fc42
    VERSION="$(rpm -q "${SECURE_TMP_DIR}/akmods-rpms/kmods/kmod-nvidia-"*.rpm | sed 's/^kmod-nvidia-//' | sed 's/\.[^.]*$//')"
    # DRIVER_VERSION format example: 590.48.01
    DRIVER_VERSION=$(echo "$VERSION" | cut -d- -f1)

    LOCAL_NVIDIA_PKG="${SECURE_TMP_DIR}/akmods-rpms/kmods/kmod-nvidia-${KERNEL_VERSION}-${NVIDIA_AKMOD_VERSION}.fc*.rpm"

    # Use DRIVER_VERSION for packages to allow minor release mismatches (e.g., -1 vs -3)
    # This helps when the repo updates before the akmods image
    NVIDIA_PKGS=(
      "libnvidia-fbc-${DRIVER_VERSION}*.x86_64"
      "libnvidia-ml-${DRIVER_VERSION}*.i686"
      "libva-nvidia-driver"
      "nvidia-driver-${DRIVER_VERSION}*.x86_64"
      "nvidia-driver-cuda-${DRIVER_VERSION}*.x86_64"
      "nvidia-driver-cuda-libs-${DRIVER_VERSION}*.i686"
      "nvidia-driver-libs-${DRIVER_VERSION}*.i686"
      "nvidia-settings-${DRIVER_VERSION}*.x86_64"
      "nvidia-container-toolkit"
    )

    NVIDIA_PKGS_FOUND_ALL="1"

    for pkg in "${NVIDIA_PKGS[@]}"; do
      if ! dnf5 info "$pkg" &>/dev/null; then
        echo "ERROR: Package not found: ${pkg}"
        package=${pkg%-${DRIVER_VERSION}*} #Do not quote. Quoting disables pattern matching and prevents the suffix removal from working as intended.
        echo "Packages found for ${package}:"
        echo "$(dnf5 list --showduplicates ${package})"
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

function akmod_sanity_check () {
  local akmod=""
  local akmod_dir="${SECURE_TMP_DIR}/akmods/kmods"

  if [[ ! -d "$akmod_dir" ]]; then
    echo "ERROR: akmods directory not found."
    exit 1
  fi

  if [[ ${#AKMODS_WANTED[@]} -gt 0 ]]; then
    for akmod in ${AKMODS_WANTED[@]}; do
      local matching_files=()
      mapfile -t matching_files < <(find "${akmod_dir}" -maxdepth 1 -type f -name "*${akmod}*" -printf '%f\n') || true
      local count=${#matching_files[@]}
      if [[ $count -eq 0 ]]; then
          echo "Error: No files found containing '${akmod}' in ${akmod_dir}"
          exit 1
      elif [[ $count -eq 1 ]]; then
          echo "Found akmod file: ${matching_files[0]}"
      else
          echo "Error: Multiple files found containing '${akmod}' in ${akmod_dir}:"
          printf '  %s\n' "${matching_files[@]}"
          exit 1
      fi
    done
  fi
}

# ----------------- Installation & Cleanup -----------------

function rpm_erase () {
  # Remove all existing kernel packages without dependency checks
  # This allows for clean kernel replacement with akmods-compatible versions
  local pkgs_to_remove=()
  local target_pkgs=("kernel" "kernel-core" "kernel-modules" "kernel-modules-core" "kernel-modules-extra" "kernel-uki-virt")

  # Query all target packages at once and extract their names
  # Filter out "is not installed" to handle cases where rpm outputs errors to stdout
  # Use sort -u to handle multiple versions of the same package
  mapfile -t pkgs_to_remove < <(rpm -q --queryformat '%{NAME}\n' "${target_pkgs[@]}" 2>/dev/null | grep -v "is not installed" | sort -u) || true

  if [[ ${#pkgs_to_remove[@]} -gt 0 ]]; then
    rpm --erase "${pkgs_to_remove[@]}" --nodeps
  fi
}

function list_packages () {
  tree "${SECURE_TMP_DIR}/akmods/kmods"
  tree "${SECURE_TMP_DIR}/akmods/ublue-os"
  tree "${SECURE_TMP_DIR}/kernel-rpms"
  if [[ $NVIDIA_WANTED == "1" ]]; then
    tree "${SECURE_TMP_DIR}/akmods-rpms/kmods"
  fi
}

function install_packages () {
  local akmod=""
  local akmods=()
  local akmod_dir="${SECURE_TMP_DIR}/akmods/kmods"

  # Install akmods
  local install_rpmfusion="false"

  for akmod in ${AKMODS_WANTED[@]}; do
    local found_files=("${akmod_dir}"/*"${akmod}"*.rpm)
    akmods+=("${found_files[@]}")

    if [[ ${akmod} =~ "v4l2loopback" ]]; then
      install_rpmfusion="true"
      akmods+=("v4l2loopback")
    fi
  done

  # Add kernel packages to the installation list
  # This ensures kernel and akmods are installed in a single transaction
  local kernel_files=("${SECURE_TMP_DIR}/kernel-rpms/"*.rpm)
  akmods+=("${kernel_files[@]}")

  if [[ "$install_rpmfusion" == "true" ]]; then
      dnf5 -y install \
          https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${FEDORA_VERSION}".noarch.rpm \
          https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${FEDORA_VERSION}".noarch.rpm
  fi

  if [[ ${#akmods[@]} -gt 0 ]]; then
    dnf5 -y install "${akmods[@]}"
  fi

  if [[ "$install_rpmfusion" == "true" ]]; then
      dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release
  fi

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
    if dnf5 repolist --all | grep -q rpmfusion; then
      dnf5 config-manager setopt "rpmfusion*".enabled=0
    fi
    
    dnf5 config-manager setopt fedora-cisco-openh264.enabled=0
    
    # Exclude golang NVIDIA container toolkit to prevent conflicts
    dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

    dnf5 install -y "${SECURE_TMP_DIR}/akmods-rpms/ublue-os/ublue-os-nvidia-addons-"*.rpm
    
    # enable repos provided by ublue-os-nvidia-addons
    dnf5 config-manager setopt fedora-nvidia.enabled=1 nvidia-container-toolkit.enabled=1
    
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
    if dnf5 repolist --enabled | grep -q "fedora-multimedia"; then
      NEGATIVO17_MULT_PREV_ENABLED=Y
      echo "disabling negativo17-fedora-multimedia to ensure negativo17-fedora-nvidia is used"
      dnf5 config-manager setopt fedora-multimedia.enabled=0
    fi
    
    # Enable staging for supergfxctl if repo file exists
    if [[ -f /etc/yum.repos.d/_copr_ublue-os-staging.repo ]]; then
      sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-staging.repo
    else
      # Otherwise, retrieve the repo file for staging
      dnf5 config-manager addrepo --from-repofile="https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-${FEDORA_VERSION}/ublue-os-staging-fedora-${FEDORA_VERSION}.repo" --overwrite --save-filename="_copr_ublue-os-staging.repo"
    fi
  fi
}

function install_nvidia_packages () {
  if [[ $NVIDIA_WANTED == "1" ]]; then
    # Remove conflicting nouveau (open-source NVIDIA) driver files
    remove /usr/share/vulkan/icd.d/nouveau_icd.*.json
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
    dnf5 config-manager setopt fedora-nvidia.enabled=0 nvidia-container-toolkit.enabled=0
    
    # Disable staging
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-staging.repo
    
    # ensure kernel.conf matches NVIDIA_FLAVOR (which must be nvidia or nvidia-open)
    # kmod-nvidia-common defaults to 'nvidia-open' but this will match our akmod image
#    sed -i "s/^MODULE_VARIANT=.*/MODULE_VARIANT=$NVIDIA_TAG/" /etc/nvidia/kernel.conf
    
    systemctl enable ublue-nvctk-cdi.service
    semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp
    
    # Universal Blue specific Initramfs fixes
    # we must force driver load to fix black screen on boot for nvidia desktops
    sed -i 's@omit_drivers@force_drivers@g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
    # as we need forced load, also mustpre-load intel/amd iGPU else chromium web browsers fail to use hardware acceleration
    sed -i 's@ nvidia @ i915 amdgpu nvidia @g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
    
    if [[ "${IMAGE_NAME}" =~ sericea|sway-atomic ]]; then
      mv /etc/sway/environment{,.orig}
      install -Dm644 /usr/share/ublue-os/etc/sway/environment /etc/sway/environment
    fi
    
    # re-enable negativo17-mutlimedia since we disabled it
    if [[ "${NEGATIVO17_MULT_PREV_ENABLED}" = "Y" ]]; then
      dnf5 config-manager setopt fedora-multimedia.enabled=1
    fi
  fi
}

function remove () {
  for target in "$@"; do
    if [[ -d "$target" ]] || [[ -f "$target" ]] ; then
      rm -rf "$target"
    fi
  done
}

function initial_cleanup () {
  remove "${SECURE_TMP_DIR}/akmods"
  remove "${SECURE_TMP_DIR}/akmods-rpms"
  remove "${SECURE_TMP_DIR}/kernel-rpms"
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
  akmod_sanity_check
  install_packages
  install_nvidia_packages
  final_cleanup
  lock_version
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
