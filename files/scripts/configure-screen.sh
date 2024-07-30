#!/usr/bin/env bash

set -ouex pipefail

# Must be over 1000
GID_SCREEN=1836

SCREEN_PATH="/usr/bin/screen"

chgrp "${GID_SCREEN}" "${SCREEN_PATH}"

cat >/usr/lib/sysusers.d/screen.conf <<EOF
g screen ${GID_SCREEN}
EOF

