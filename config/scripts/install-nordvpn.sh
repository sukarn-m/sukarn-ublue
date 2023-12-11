#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

ARCH=$(uname -m)

REPO_LISTING=$(curl --silent --fail --location https://repo.nordvpn.com/yum/nordvpn/centos/x86_64/Packages/n/)

releases=($(echo $REPO_LISTING | grep -Po "nordvpn-[0-9\.\-]+${ARCH}\.rpm"))

latest_release=${releases[-1]}

echo "Latest nordvpn release: $latest_release"

rpm-ostree install https://repo.nordvpn.com/yum/nordvpn/centos/${ARCH}/Packages/n/${latest_release}

echo "Done installing nordvpn."
