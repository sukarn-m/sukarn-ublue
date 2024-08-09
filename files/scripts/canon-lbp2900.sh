#!/usr/bin/env bash

set -ouex pipefail

## From open source captdriver:
# Add USB quirks to fix printer issues.
echo "# LBP2900" >> /usr/share/cups/usb/org.cups.usb-quirks
echo "0x04a9 0x2676 no-reattach" >> /usr/share/cups/usb/org.cups.usb-quirks

## Add the printer.
# Run as root after installation:
# ujust add-canon-lbp2900b
