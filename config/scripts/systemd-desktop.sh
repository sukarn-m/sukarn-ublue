#!/usr/bin/env bash

systemctl daemon-reload
systemctl enable desktop-kargs.service
chmod 0700 /usr/bin/desktop-kargs
