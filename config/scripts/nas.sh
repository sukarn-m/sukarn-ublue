#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# Set permissions for certificate generation script.
chmod 0700 /usr/bin/generate-ssh-certificate.sh
chcon -u system_u -t bin_t /usr/bin/generate-ssh-certificate.sh

# Set permissions for nas mountpoints.
chmod 0644 /usr/lib/systemd/system/var-mnt-nas.mount /usr/lib/systemd/system/var-mnt-nas.automount
chcon -u system_u -t systemd_unit_file_t /usr/lib/systemd/system/var-mnt-nas.mount
chcon -u system_u -t systemd_unit_file_t /usr/lib/systemd/system/var-mnt-nas.automount

# Enable everything
systemctl daemon-reload
systemctl enable var-mnt-nas.mount var-mnt-nas.automount
systemctl enable generate-ssh-certificate.service
