#!/usr/bin/bash

set -ouex pipefail

filename="/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/appIcons.js"

sed -i "s/'System monitor'/'Mission Center'/" ${filename}
sed -i "s/'gnome-system-monitor'/'flatpak run io.missioncenter.MissionCenter'/" ${filename}
sed -i "s/'Terminal'/'Ptyxis Terminal'/" ${filename}
sed -i "s/'gnome-terminal'/'flatpak run app.devsuite.Ptyxis --new-window'/" ${filename}
sed -i "s/'Extensions'/'Extensions Manager'/" ${filename}
sed -i "s/'gnome-shell-extension-prefs'/'flatpak run com.mattjakeman.ExtensionManager'/" ${filename}
