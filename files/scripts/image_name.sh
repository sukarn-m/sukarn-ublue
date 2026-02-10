#!/usr/bin/env bash

set -oue pipefail

NAME="${IMAGE_DISTRO_NAME:-Sukarn Linux}"
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/usr/lib/os-release}"
FEDORA_RELEASE_FILE="${FEDORA_RELEASE_FILE:-/etc/fedora-release}"

IMAGE_DATE=$(date +%Y%m%d.%H)
MAJOR_RELEASE_VERSION=$(grep -oP '[0-9]*' "${FEDORA_RELEASE_FILE}")
sed -i "s,^PRETTY_NAME=.*,PRETTY_NAME=\"${NAME} ${MAJOR_RELEASE_VERSION}.${IMAGE_DATE}\"," "${OS_RELEASE_FILE}"
