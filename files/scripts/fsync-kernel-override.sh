#!/usr/bin/env bash

## Instructions:
## In the rpm-ostree module, add the following in the repos section; adjust fedora version or check https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos for updated .repo link:
##     repos:
##      - https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos-lto/repo/fedora-41/bieszczaders-kernel-cachyos-lto-fedora-41.repo

set -oue pipefail

# inspired by: https://github.com/antuan1996/formile-cachyos-ublue

echo 'Enable SElinux policy'
setsebool -P domain_kernel_load_modules on

echo 'fsync kernel override'
rpm-ostree override replace --experimental --freeze --from repo='copr:copr.fedorainfracloud.org:sentry:kernel-fsync' kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
