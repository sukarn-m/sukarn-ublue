#!/bin/bash

# Tell build process to exit if there are any errors.
set -oue pipefail

file_path="/usr/bin/bazzite-hardware-setup"

sed -i "s,^IMAGE_FLAVOR=.*,IMAGE_FLAVOR=nvidia," ${file_path}
