#!/usr/bin/env bash

set -ouex pipefail

## From open source captdriver:
# Add USB quirks to fix printer issues.
echo "# LBP2900" >> /usr/share/cups/usb/org.cups.usb-quirks
echo "0x04a9 0x2676 no-reattach" >> /usr/share/cups/usb/org.cups.usb-quirks

## Add the printer.
# Run as root after installation:
# lpadmin -p 'LBP2900B' -v usb://Canon/LBP2900?serial=0000C1E62I7Z -P /usr/share/cups/model/CanonLBP-2900-3000.ppd -L 'Canon LBP2900B' -E