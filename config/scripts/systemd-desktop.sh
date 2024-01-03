#!/usr/bin/env bash

systemctl daemon-reload
systemctl enable nvidia-kargs.service
chmod 0700 /usr/bin/nvidia-kargs
