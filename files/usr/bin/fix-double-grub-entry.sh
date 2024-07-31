#!/bin/bash

set -oeux pipefail

if [ -d /sys/firmware/efi ]; then
  grub2-switch-to-blscfg
  grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
else
  block_device=$(lsblk -spnlo name $(grub2-probe --target=device /boot/grub2) | tail -n1)
  grub2-install $block_device
  touch /boot/grub2/.grub2-blscfg-supported
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi
