#!/usr/bin/env bash

systemctl daemon-reload
systemctl enable generate-ssh-certificate.service
systemctl enable var-mnt-nas.automount
systemctl enable var-mnt-nas.mount
systemctl enable var-mnt-roms.automount
systemctl enable var-mnt-roms.mount
