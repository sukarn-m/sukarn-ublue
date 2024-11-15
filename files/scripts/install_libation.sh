#!/usr/bin/bash

# Stop running if an error is encountered.
set -oeu pipefail

# Configuration
software="Libation"
owner="rmcrackan"
repo="${owner}/${software}"
architecture="amd64"
storage_location="/tmp/libation"
filetype="rpm"
package_install="rpm-ostree install"

# Make the directory if it doesn't already exist.
mkdir -p ${storage_location}

# Function to download the package.
function download_package () {
  echo "Downloading ${latest_release_file} to ${storage_location}"
  wget --quiet -O "${storage_location}/${latest_release_file}" "${latest_release_url}"
  echo "${latest_release_file} downloaded."
}

# Get all latest release information.
latest_release_url=$(curl -s https://api.github.com/repos/${repo}/releases/latest | grep "browser_download_url.*-${architecture}.${filetype}" | cut -d : -f 2,3 | tr -d \" | xargs)
latest_release_file=$(basename ${latest_release_url})
latest_version=$(echo ${latest_release_file} | grep -oE '[0-9\.]+' | head -1 | cut --character 2-)

# Download the file if needed.
if [[ $(ls ${storage_location}/${software}*.${filetype}) ]]; then
  downloaded_version=$(ls ${storage_location}/${software}*.${filetype} | grep -oE '[0-9\.]+' | head -1 | cut --character 2-) || true
  if [[ ${latest_version} != ${downloaded_version} ]]; then
    rm -v "$storage_location}/${software}*.${filetype}"
    download_package
  fi
else
  downloaded_version=""
  download_package
fi

# Install the file.
${package_install} ${storage_location}/${latest_release_file}

# Remove leftovers
rm -r ${storage_location}
