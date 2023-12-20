#!/usr/bin/env bash

systemctl daemon-reload
systemctl enable laptop-kargs.service
chmod 0700 /usr/bin/laptop-kargs
