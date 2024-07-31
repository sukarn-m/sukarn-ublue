#!/usr/bin/bash

## Based on:
## https://github.com/ublue-os/bluefin/blob/da83af82256e35e84e51e93de3958ac1eb9d8de6/scripts/build-image.sh#L24

set -eou pipefail

coreos_kernel_release=$(skopeo inspect docker://quay.io/fedora/fedora-coreos:stable | jq -r '.Labels["ostree.linux"] | split(".x86_64")[0]')
coreos_major_minor_patch=$(echo "$coreos_kernel_release" | cut -d '-' -f 1)
running_fedora_release=$(grep -Po "(?<=VERSION_ID=)\d+" /usr/lib/os-release)

if $(rpm -q budgie-desktop)
    echo "Budgie variant detected. Skipping major minor version check."
else
    running_major_minor_patch=$(rpm  -q kernel | cut -d '-' -f2- | cut -d '-' -f1-1)
    
    echo "coreos kernel release: ${coreos_major_minor_patch}"
    echo "running kernel release: ${running_major_minor_patch}"
    
    ## Stop the script if the kernel major and minor versions between fedora and coreos match.
    if [ "$(echo "$running_major_minor_patch" | cut -d'.' -f1-2)" == "$(echo "$coreos_major_minor_patch" | cut -d'.' -f1-2)" ]; then
        echo "Kernel major and minor versions between coreos and fc${running_fedora_release} match, exiting script."
        exit 0
    fi
    
    ## If we reach this point, the major and minor versions do not match, continue running the script
    echo "Kernel major and minor versions between coreos and fc${running_fedora_release} do not match, continuing script..."
fi

dir_names=$(curl -sS https://kojipkgs.fedoraproject.org/packages/kernel/${coreos_major_minor_patch}/ 2>&1 | grep '<a href=' | sed 's|^<a href="\([^"]*\)">.*|\1|')
for dir_name in $dir_names; do
    if [[ $dir_name =~ fc${running_fedora_release} ]]; then
        coreos_kernel_subnum=$(echo $dir_name | grep -oE '[0-9]{3}' | head -1)
        break
    fi
done

## Set variables for downloading the appropriate files.
KERNEL_VERSION="${coreos_major_minor_patch}-${coreos_kernel_subnum}.fc$(("$running_fedora_release"))"
KERNEL_MAJOR_MINOR_PATCH=${coreos_major_minor_patch}
KERNEL_RELEASE=$(echo "$KERNEL_VERSION" | cut -d '-' -f 2)

## If kernel-tools is installed, downgrade kernel-tools and kernel-tools-libs.
if rpm -q kernel-tools; then
    rpm-ostree override replace --experimental \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-core-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-core-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-extra-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-tools-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-tools-libs-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm"
else
    rpm-ostree override replace --experimental \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-core-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-core-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm" \
        "https://kojipkgs.fedoraproject.org/packages/kernel/$KERNEL_MAJOR_MINOR_PATCH/$KERNEL_RELEASE/x86_64/kernel-modules-extra-$KERNEL_MAJOR_MINOR_PATCH-$KERNEL_RELEASE.x86_64.rpm"
fi