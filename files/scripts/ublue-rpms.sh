#!/usr/bin/env bash

## Only for non-ublue derived images.

set -oue pipefail

# To get the list of packages available in a workflow log:
tree /tmp && exit 1

# rpm-ostree install /tmp/config-rpms/*.noarch.rpm

# Skipping installation of ublue-os-signing.noarch.rpm:
rpm-ostree install \
/tmp/config-rpms/ublue-os-just.noarch.rpm \
/tmp/config-rpms/ublue-os-luks.noarch.rpm \
/tmp/config-rpms/ublue-os-udev-rules.noarch.rpm \
/tmp/config-rpms/ublue-os-update-services.noarch.rpm

rpm-ostree override replace --experimental /tmp/kernel-rpms/*.rpm

rm -rv /tmp/config-rpms
rm -rv /tmp/kernel-rpms
