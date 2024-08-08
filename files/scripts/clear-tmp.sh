#!/bin/bash

set -oeu pipefail

if [ -d /tmp/rpm-repos ]; then
  rm -rfv /tmp/rpm-repos
fi

if [ -d /tmp/kernel-rpms ]; then
  rm -rfv /tmp/kernel-rpms
fi

if [-d /tmp/config-rpms ]; then
  rm -rfv /tmp/config-rpms
fi
