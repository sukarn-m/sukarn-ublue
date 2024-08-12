# vim: set ft=make :
# This file can be modified downstream to add custom just commands

# Remove NFS caching and cached files
remove-nfs-cache:
    #!/usr/bin/bash
    sudo systemctl disable --now cachefilesd.service
    sudo rm -rf /var/cache/fscache

# Enable NFS caching
enable-nfs-cache:
    #!/usr/bin/bash
    sudo mkdir -p /var/cache/fscache
    sudo restorecon -RF /var/cache/fscache
    sudo systemctl enable --now cachefilesd.service

# Add Canon LBP2900B printer
add-canon-lbp2900b:
    #!/usr/bin/bash
    sudo lpadmin -p 'LBP2900B' -v usb://Canon/LBP2900?serial=0000C1E62I7Z -P /usr/share/cups/model/CanonLBP-2900-3000.ppd -L 'Canon LBP2900B' -E

fix-grub-double-entry:
    #!/usr/bin/bash
    if [ -d /sys/firmware/efi ]; then
      sudo grub2-switch-to-blscfg
      sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    else
      block_device=$(lsblk -spnlo name $(grub2-probe --target=device /boot/grub2) | tail -n1)
      sudo grub2-install $block_device
      sudo touch /boot/grub2/.grub2-blscfg-supported
      sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    fi

enroll-fedora-certificate:
    #!/usr/bin/bash
    wget --output-document=/tmp/fedora-ca.cer https://src.fedoraproject.org/rpms/shim-unsigned-x64/blob/rawhide/f/fedora-ca-20200709.cer
    sudo mokutil --timeout -1
    sudo mokutil --import /tmp/fedora-ca.cer
    sudo systemctl reboot
