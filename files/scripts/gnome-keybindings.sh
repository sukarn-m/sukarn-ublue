#!/usr/bin/env bash

## Tell build process to exit if there are any errors.
set -oue pipefail

## Custom keybindings use a relocatable schema, which gschema overrides cannot set.
## Ship them as system-wide dconf defaults instead (users can still override them).

profile="/etc/dconf/profile/user"
mkdir -p /etc/dconf/profile /etc/dconf/db/local.d

if [[ ! -f "${profile}" ]]; then
  printf 'user-db:user\nsystem-db:local\n' > "${profile}"
elif ! grep -qx 'system-db:local' "${profile}"; then
  echo 'system-db:local' >> "${profile}"
fi

cat > /etc/dconf/db/local.d/50-sukarn-keybindings <<'EOF'
[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='F12'
command='ptyxis --new-window'
name='Terminal'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
binding='Favorites'
command='ptyxis --new-window'
name='Terminal'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
binding='<Control><Shift>Escape'
command='flatpak run io.missioncenter.MissionCenter'
name='Mission Center'
EOF

dconf update
