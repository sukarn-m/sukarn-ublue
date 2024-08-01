#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

rpm-ostree install /tmp/rpms/*.noarch.rpm