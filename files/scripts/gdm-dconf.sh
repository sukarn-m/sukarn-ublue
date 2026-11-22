#!/usr/bin/env bash

## Tell build process to exit if there are any errors.
set -oue pipefail

## Compile the GDM greeter dconf database after files/desktop installs its
## drop-ins. dconf does not compile /etc/dconf/db/gdm.d at runtime.

dconf update
