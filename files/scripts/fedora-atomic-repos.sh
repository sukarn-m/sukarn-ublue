#!/usr/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"

RPMFUSION_MIRROR_RPMS="https://mirrors.rpmfusion.org"

REPO_DIR=$(mktemp -d)
trap 'rm -rf "${REPO_DIR}"' EXIT

curl -Lo "${REPO_DIR}/rpmfusion-free-release-${RELEASE}.noarch.rpm" "${RPMFUSION_MIRROR_RPMS}/free/fedora/rpmfusion-free-release-${RELEASE}.noarch.rpm"
curl -Lo "${REPO_DIR}/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm" "${RPMFUSION_MIRROR_RPMS}/nonfree/fedora/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm"

dnf5 config-manager addrepo --from-repofile="https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-${RELEASE}/ublue-os-staging-fedora-${RELEASE}.repo" --overwrite --save-filename="_copr_ublue-os_staging.repo"
dnf5 config-manager addrepo --from-repofile="https://copr.fedorainfracloud.org/coprs/kylegospo/oversteer/repo/fedora-${RELEASE}/kylegospo-oversteer-fedora-${RELEASE}.repo" --overwrite --save-filename="_copr_kylegospo_oversteer.repo"
dnf5 config-manager addrepo --from-repofile="https://copr.fedorainfracloud.org/coprs/ublue-os/akmods/repo/fedora-${RELEASE}/ublue-os-akmods-fedora-${RELEASE}.repo" --overwrite --save-filename="_copr_ublue-os-akmods.repo"

dnf5 config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo" --overwrite --save-filename="negativo17-fedora-multimedia.repo"

rpm-ostree install \
    "${REPO_DIR}"/*.rpm \
    fedora-repos-archive
