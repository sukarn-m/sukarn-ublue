#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

if [[ -f /usr/bin/laptop-kargs ]]; then
  chmod 0700 /usr/bin/laptop-kargs
elif [[ -f /usr/bin/desktop-kargs ]]; then
  chmod 0700 /usr/bin/desktop-kargs
fi
