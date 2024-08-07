#!/usr/bin/env bash

## Only for non-ublue derived images.

set -oue pipefail

rpm-ostree install /tmp/config-rpms/*.noarch.rpm