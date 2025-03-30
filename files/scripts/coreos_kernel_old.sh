#!/usr/bin/bash

# Set bash options for error handling and variable safety
# -e: Exit immediately if a command exits with non-zero status
# -o pipefail: Return value of a pipeline is the value of the last command to exit with non-zero status
# -u: Treat unset variables as an error
set -eou pipefail

# Get the kernel release version from the stable Fedora CoreOS container image
coreos_kernel_release=$(skopeo inspect docker://quay.io/fedora/fedora-coreos:stable | jq -r '.Labels["ostree.linux"] | split(".x86_64")[0]')

# Extract the major.minor.patch version from the kernel release
coreos_major_minor_patch=$(echo "$coreos_kernel_release" | cut -d '-' -f 1)

# Get the running Fedora release version from os-release file
running_fedora_release=$(grep -Po "(?<=VERSION_ID=)\d+" /usr/lib/os-release)

# Fetch directory names from Fedora's Koji build system for the specific kernel version
dir_names=$(curl -sS https://kojipkgs.fedoraproject.org/packages/kernel/${coreos_major_minor_patch}/ 2>&1 | grep '<a href=' | sed 's|^<a href="\([^"]*\)">.*|\1|')

# Find the appropriate kernel build for the current Fedora release
for dir_name in $dir_names; do
    if [[ $dir_name =~ fc${running_fedora_release} ]]; then
        # Extract the kernel subversion number
        coreos_kernel_subnum=$(echo $dir_name | grep -oE '[0-9]{3}' | head -1)
        break
    fi
done

## Set variables for downloading the appropriate files.
# Construct the full kernel version string
KERNEL_VERSION="${coreos_major_minor_patch}-${coreos_kernel_subnum}.fc${running_fedora_release}"
# Store the major.minor.patch for later use
KERNEL_MAJOR_MINOR_PATCH=${coreos_major_minor_patch}
# Extract the release number from the kernel version
KERNEL_RELEASE=$(echo "$KERNEL_VERSION" | cut -d '-' -f 2)

# Install packages to the root filesystem
# rpm-ostree cliwrap install-to-root /

# Initialize an empty array to store needed packages
NEEDED_PACKAGES=()

# Dynamically determine which kernel packages are installed on the system and add them to the NEEDED_PACKAGES array
for package in $(rpm -qa | grep kernel); do
    # Extract the package name without version information
    package_name=$(echo "$package" | sed -E 's/(-[0-9].*)$//')
    
    # Add the package name to the array
    NEEDED_PACKAGES+=("$package_name")
done

# Remove kernel-headers from the list
NEEDED_PACKAGES=(${NEEDED_PACKAGES[@]/kernel-headers})

# Build the URL list for all needed packages
PACKAGES_LIST=""
for package in "${NEEDED_PACKAGES[@]}"; do
  PACKAGES_LIST="${PACKAGES_LIST} https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/$package-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm"
done

# Replace the current kernel packages with the versions from Koji
# --experimental flag is required for this operation
rpm-ostree override replace --experimental $PACKAGES_LIST

