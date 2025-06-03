#!/usr/bin/bash

set -oue pipefail

function gschemas_compile () {
  local current_dir="$(pwd)"
  cd /usr/share/glib-2.0/schemas/
  glib-compile-schemas .
  cd "${current_dir}"
}

gschemas_compile

