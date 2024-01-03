#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# Set permissions for certificate generation script.
chmod 0700 /usr/bin/generate-ssh-certificate.sh

# Set permissions for nas mountpoints.
chmod 0644 /usr/lib/systemd/system/var-mnt-nas.mount /usr/lib/systemd/system/var-mnt-nas.automount
