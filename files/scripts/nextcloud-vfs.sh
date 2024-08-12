#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# On Fedora, nextcloud-client does not contain the libraries for virtual files support. Flatpak and AppImage do not integrate with Nautilus.

echo "Linking nextcloud libraries to enable virtual files support."
ln -s -v /usr/lib64/nextcloudsync_vfs_suffix.so /usr/lib64/qt5/plugins/nextcloudsync_vfs_suffix.so
ln -s -v /usr/lib64/nextcloudsync_vfs_xattr.so /usr/lib64/qt5/plugins/nextcloudsync_vfs_xattr.so
