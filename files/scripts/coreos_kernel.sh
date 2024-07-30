#!/usr/bin/bash

## Based on:
## https://github.com/ublue-os/bluefin/blob/da83af82256e35e84e51e93de3958ac1eb9d8de6/scripts/build-image.sh#L24

set -eoux pipefail

coreos_kernel_release=$(skopeo inspect docker://quay.io/fedora/fedora-coreos:stable | jq -r '.Labels["ostree.linux"] | split(".x86_64")[0]')
major_minor_patch=$(echo "$coreos_kernel_release" | cut -d '-' -f 1)
latest_fedora_version=$(echo "$coreos_kernel_release" | grep -oP 'fc\K[0-9]+')
running_fedora_version=$(grep -Po "(?<=VERSION_ID=)\d+" /usr/lib/os-release)
if [ $running_fedora_version -eq $latest_fedora_version ]; then
    coreos_kernel_subnum=300
elif [ $running_fedora_version -eq $(($latest_fedora_version - 1)) ]; then
    coreos_kernel_subnum=200
elif [ $running_fedora_version -eq $(($latest_fedora_version - 2)) ]; then
    coreos_kernel_subnum=100
else
    echo "Fedora version mismatch in coreos_kernel.sh"
    exit 1
fi
KERNEL_VERSION="${major_minor_patch}-${coreos_kernel_subnum}.fc$(("$running_fedora_version"))"
KERNEL_MAJOR_MINOR_PATCH=$(echo "$KERNEL_VERSION" | cut -d '-' -f 1)
KERNEL_RELEASE=$(echo "$KERNEL_VERSION" | cut -d '-' -f 2)

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