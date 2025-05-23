#!/usr/bin/bash

## Reference: https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh

set -eou pipefail

AKMODS_FLAVOR="coreos-stable"
KERNEL_PRE="$(rpm -q kernel | sed 's/^kernel-//')"
FEDORA_VERSION="$(rpm -E %fedora)"

echo "${AKMODS_FLAVOR}-${FEDORA_VERSION}" > /tmp/kernel_tag

for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt; do
    rpm --erase $pkg --nodeps
done

skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"${FEDORA_VERSION}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

dnf5 -y install /tmp/kernel-rpms/*.rpm

dnf5 -y install \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*xpadneo*.rpm

# RPMFUSION Dependent AKMODS
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${FEDORA_VERSION}".noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${FEDORA_VERSION}".noarch.rpm
dnf5 -y install \
    v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm

dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

KERNEL_POST="$(rpm -q kernel | sed 's/^kernel-//')"

if [ "$KERNEL_PRE" != "$KERNEL_POST" ]; then
    rm -rf "/usr/lib/modules/${KERNEL_PRE}"
    rm -rf "/usr/share/doc/kernel-keys/${KERNEL_PRE}"
    rm -rf "/usr/src/kernels/${KERNEL_PRE}"
fi

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra
