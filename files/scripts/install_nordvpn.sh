#!/usr/bin/env bash
set -euo pipefail

echo "Installing NordVPN..."

NORDVPN_REPO_URL="https://repo.nordvpn.com/yum/nordvpn/centos/x86_64/"
NORDVPN_GPG_URL="https://repo.nordvpn.com/gpg/nordvpn_public.asc"
REPO_FILE="/etc/yum.repos.d/nordvpn.repo"

rpm --import "${NORDVPN_GPG_URL}"

cat > "${REPO_FILE}" <<EOF
[nordvpn]
name=NordVPN
baseurl=${NORDVPN_REPO_URL}
enabled=1
gpgcheck=1
gpgkey=${NORDVPN_GPG_URL}
EOF

dnf5 install -y nordvpn
