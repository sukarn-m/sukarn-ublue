#!/usr/bin/bash

set -oue pipefail

function remove () {
  if [[ -d "$1" ]] || [[ -f "$1" ]] ; then
    rm -r "$1"
  fi
}

remove /tmp/nvidia
remove /tmp/kernel
remove /tmp/kernel-bazzite
remove /tmp/kernel-gated
remove /tmp/akmods
remove /tmp/kernel-rpms
remove /tmp/akmods-rpms
