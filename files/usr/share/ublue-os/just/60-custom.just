# vim: set ft=make :
# This file can be modified downstream to add custom just commands

# Remove NFS caching and cached files
remove-nfs-cache:
    #!/usr/bin/bash
    systemctl disable --now cachefilesd.service
    rm -rf /var/cache/fscache

# Enable NFS caching
enable-nfs-cache:
    #!/usr/bin/bash
    mkdir -p /var/cache/fscache
    restorecon -RF /var/cache/fscache
    systemctl enable --now cachefilesd.service
