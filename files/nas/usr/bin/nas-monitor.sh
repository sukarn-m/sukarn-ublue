#!/bin/bash

function systemctl_start () {
  if [ ! $(systemctl is-active --quiet $1) ]; then
    systemctl start $1
  fi
}

function systemctl_stop () {
  if [ $(systemctl is-active --quiet $1) ]; then
    systemctl stop $1
  fi
}

if ping -c 1 truenas.home &> /dev/null
then
  systemctl_start var-mnt-nas.automount
	systemctl_start var-mnt-roms.automount
else
	systemctl_stop var-mnt-nas.automount
	systemctl_stop var-mnt-nas.mount
	systemctl_stop var-mnt-roms.automount
	systemctl_stop var-mnt-roms.mount
fi
