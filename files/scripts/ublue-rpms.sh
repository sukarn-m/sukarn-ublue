#!/usr/bin/env bash

## Only for non-ublue derived images.

set -oue pipefail

tree /tmp/
exit 1

# rpm-ostree install /tmp/config-rpms/*.noarch.rpm
rpm-ostree install \
/tmp/config-rpms/ublue-os-just*.noarch.rpm \
/tmp/config-rpms/ublue-os-luks*.noarch.rpm \
/tmp/config-rpms/ublue-os-udev-rules*.noarch.rpm \
/tmp/config-rpms/ublue-os-update-services*.noarch.rpm