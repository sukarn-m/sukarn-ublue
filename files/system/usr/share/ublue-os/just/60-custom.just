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


