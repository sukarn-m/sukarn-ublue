#!/usr/bin/env bash

## Tell build process to exit if there are any errors.
set -oue pipefail

## Set permissions for certificate generation script.
chmod 0700 /usr/bin/generate-ssh-certificate.sh

## Set permissions for nas mountpoints. Unnecessary.
# chmod 0644 /usr/lib/systemd/system/var-mnt-nas.mount /usr/lib/systemd/system/var-mnt-nas.automount

## Set permissions for nas-monitor.
chmod 0700 /usr/bin/nas-monitor.sh
# chmod 0644 /usr/lib/systemd/system/nas-monitor.service /usr/lib/systemd/system/nas-monitor.timer # Unnecessary
