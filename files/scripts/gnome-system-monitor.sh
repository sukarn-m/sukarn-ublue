#!/usr/bin/bash

set -ouex pipefail

if [[ -f /usr/share/applications/gnome-system-monitor.desktop ]]; then
    sed -i 's/TryExec=gnome-system-monitor/TryExec=flatpak run io.missioncenter.MissionCenter/' /usr/share/applications/gnome-system-monitor.desktop
fi
if [[ -f /usr/share/applications/org.gnome.SystemMonitor.desktop ]]; then
    sed -i 's/TryExec=gnome-system-monitor/TryExec=flatpak run io.missioncenter.MissionCenter/' /usr/share/applications/org.gnome.SystemMonitor.desktop
fi
