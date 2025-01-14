#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

find /tmp/rpms
rpm-ostree install /tmp/rpms/ublue-os/ublue-os-nvidia*.rpm
sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/nvidia-container-toolkit.repo
sed -i '0,/enabled=0/{s/enabled=0/enabled=1\npriority=90/}' /etc/yum.repos.d/negativo17-fedora-nvidia.repo   
rpm-ostree install /tmp/rpms/kmods/kmod-nvidia*.rpm libnvidia-fbc libva-nvidia-driver nvidia-driver nvidia-driver-cuda nvidia-modprobe nvidia-persistenced nvidia-settings nvidia-container-toolkit 
semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp
rm -f /etc/yum.repos.d/negativo17-fedora-nvidia.repo
rm -f /etc/yum.repos.d/negativo17-fedora-multimedia.repo
rm -f /etc/yum.repos.d/nvidia-container-toolkit.repo
sed -i 's@omit_drivers@force_drivers@g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
sed -i 's@ nvidia @ i915 amdgpu nvidia @g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
# echo "options nvidia-drm modeset=1 fbdev=1" > /usr/lib/modprobe.d/nvidia-modeset.conf
# cp /usr/lib/modprobe.d/nvidia-modeset.conf /etc/modprobe.d/nvidia-modeset.conf
