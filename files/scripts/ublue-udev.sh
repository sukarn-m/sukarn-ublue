#!/usr/bin/bash

set -oue pipefail

cp -a /usr/share/ublue-os/game-devices-udev/*.rules /etc/udev/rules.d/
