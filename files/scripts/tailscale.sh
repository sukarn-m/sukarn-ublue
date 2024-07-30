#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

wget https://pkgs.tailscale.com/stable/fedora/tailscale.repo -P /etc/yum.repos.d/
rpm-ostree install tailscale
