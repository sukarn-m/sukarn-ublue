#!/usr/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"

RPMFUSION_MIRROR_RPMS="https://mirrors.rpmfusion.org"

mkdir -p /tmp/rpm-repos

# Parallelize curl downloads
pids=()

curl -Lo /tmp/rpm-repos/rpmfusion-free-release-"${RELEASE}".noarch.rpm "${RPMFUSION_MIRROR_RPMS}"/free/fedora/rpmfusion-free-release-"${RELEASE}".noarch.rpm &
pids+=($!)

curl -Lo /tmp/rpm-repos/rpmfusion-nonfree-release-"${RELEASE}".noarch.rpm "${RPMFUSION_MIRROR_RPMS}"/nonfree/fedora/rpmfusion-nonfree-release-"${RELEASE}".noarch.rpm &
pids+=($!)

curl -Lo /etc/yum.repos.d/_copr_ublue-os_staging.repo https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${RELEASE}"/ublue-os-staging-fedora-"${RELEASE}".repo &
pids+=($!)

curl -Lo /etc/yum.repos.d/_copr_kylegospo_oversteer.repo https://copr.fedorainfracloud.org/coprs/kylegospo/oversteer/repo/fedora-"${RELEASE}"/kylegospo-oversteer-fedora-"${RELEASE}".repo &
pids+=($!)

curl -Lo /etc/yum.repos.d/_copr_ublue-os-akmods.repo https://copr.fedorainfracloud.org/coprs/ublue-os/akmods/repo/fedora-"${RELEASE}"/ublue-os-akmods-fedora-"${RELEASE}".repo &
pids+=($!)

curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo &
pids+=($!)

for pid in "${pids[@]}"; do
    wait "$pid"
done

rpm-ostree install \
    /tmp/rpm-repos/*.rpm \
    fedora-repos-archive

rm -rv /tmp/rpm-repos
