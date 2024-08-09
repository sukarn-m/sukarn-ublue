#!/bin/bash

if ping -c 1 truenas.home &> /dev/null
then
	systemctl start var-mnt-nas.automount
	systemctl start var-mnt-roms.automount
else
	systemctl stop var-mnt-nas.automount
	systemctl stop var-mnt-nas.mount
	systemctl stop var-mnt-roms.automount
	systemctl stop var-mnt-roms.mount
fi
