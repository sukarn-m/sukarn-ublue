#!/bin/bash

set -oeu pipefail

# Define the file path
rpm_ostreed_automatic_service="/etc/systemd/system/rpm-ostreed-automatic.service.d/override.conf"
rpm_ostreed_automatic_timer="/etc/systemd/system/rpm-ostreed-automatic.timer.d/override.conf"

# Insert the required lines under the [Unit] heading
sed -i '/\[Unit\]/a Requires=ac.target\nConflicts=battery.target' "${rpm_ostreed_automatic_service}"
sed -i '1i [Unit]\nPartOf=ac.target\n' "${rpm_ostreed_automatic_timer}"
