#!/bin/bash

set -oeu pipefail

package="captdriver"
version="0.1.4.git"
full_name="${package}-${version}"
git_link="https://github.com/mounaiban/captdriver.git"
build_dependencies="@development-tools automake autoconf cups-devel"



mkdir -p SOURCES
cd SOURCES

if [[ -f "/run/.containerenv" ]]; then
  if [[ ! -f "/usr/local/bin/ppdc" ]]; then
    sudo ln -s /usr/bin/distrobox-host-exec /usr/local/bin/ppdc
  fi
fi

sudo dnf install -y ${build_dependencies}

git clone ${git_link} ${full_name}

if [[ -f "${full_name}.tar.gz" ]]; then
  rm "${full_name}.tar.gz"
fi

tar -caf "${full_name}.tar.gz" "${full_name}"
rm -rf "${full_name}"

echo "================================================="
echo "Source file saved as SOURCES/${full_name}.tar.gz"
echo "================================================="
echo "Build steps in the source directory:"
echo "tar -xf ${full_name}.tar.gz && cd ${full_name}"
echo "aclocal && autoconf && automake --add-missing && ./configure && make && make ppd"
echo "================================================="
echo "Useful files:"
echo "src/rastertocapt -> /usr/bin/"
echo "src/rastertocapt -> /usr/libs/cups/filter/"
echo "ppd/*.ppd -> /usr/share/cups/model/"
echo "AUTHORS -> /usr/share/doc/captdriver/"
echo "COPYING -> /usr/share/doc/captdriver/"
echo "README.md -> /usr/share/doc/captdriver/"
echo "================================================="
