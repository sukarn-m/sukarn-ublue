#!/bin/bash

set -oeu pipefail

# Timers that are PartOf=ac.target (see files/laptop and files/device-e14g2) get
# stopped when battery.target starts. Make ac.target pull them back in when AC
# power returns, but only the timers this image actually enables.
timers=(
  bootc-fetch-apply-updates.timer
  podman-auto-update.timer
)

wants_dir="/etc/systemd/system/ac.target.wants"
mkdir -p "${wants_dir}"

for timer in "${timers[@]}"; do
  if systemctl is-enabled --quiet "${timer}" 2>/dev/null && [[ -f "/usr/lib/systemd/system/${timer}" ]]; then
    ln -sfv "/usr/lib/systemd/system/${timer}" "${wants_dir}/${timer}"
  fi
done
