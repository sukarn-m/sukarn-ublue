#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

file=/usr/etc/containers/registries.d/sukarn-os-base.yaml

if [ -f "${file}" ]; then
  rm -v "${file}"
fi
