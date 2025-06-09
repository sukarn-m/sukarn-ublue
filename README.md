# sukarn-ublue

[![build-gnome](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build-gnome.yml/badge.svg)](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build-gnome.yml) [![build-others](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build-others.yml/badge.svg)](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build-others.yml)

This is a constantly updating repository for creating [a native container image](https://fedoraproject.org/wiki/Changes/OstreeNativeContainerStable) designed to be customized.

**Based on BlueBuild Template**: See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for quick setup instructions for setting up your own repository based on this template.

## Table of Contents

1. [Installation by rebasing from Silverblue](#installation-by-rebasing-from-silverblue)
    1. [Rebasing to `sukarn-ublue-desktop`](#rebasing-to-sukarn-ublue-desktop)
    2. [Rebasing to `sukarn-ublue-laptop`](#rebasing-to-sukarn-ublue-laptop)
    3. [Rebasing to `sukarn-ublue-budgie`](#rebasing-to-sukarn-ublue-budgie)
    4. [Pinning to a Specific Tag](#pinning-to-a-specific-tag)
2. [Secure Boot](#secure-boot)
    1. [Fedora's certificate](#fedoras-certificate)
    2. [Universal-Blue's certificate](#universal-blues-certificate)
3. [Encrypted Drives](#encrypted-drives)
    1. [Enable Auto-Unlock Using TPM2](#enable-auto-unlock-using-tpm2)
    2. [Disable Auto-Unlock Using TPM2](#disable-auto-unlock-using-tpm2)
4. [Custom Commands](#custom-commands)
5. [ISO](#iso)
6. [Verification](#verification)

---

## Installation by rebasing from Silverblue

To rebase an existing Silverblue installation to the latest build:

### Rebasing to `sukarn-ublue-desktop`

First rebase to the unsigned image, to get the proper signing keys and policies installed. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/sukarn-m/sukarn-ublue-desktop:latest --reboot
```

Then rebase to the signed image. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-desktop:latest --reboot
```

[Go back to Table of Contents](#table-of-contents)

### Rebasing to `sukarn-ublue-laptop`

First rebase to the unsigned image, to get the proper signing keys and policies installed. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/sukarn-m/sukarn-ublue-laptop:latest --reboot
```

Then rebase to the signed image. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-laptop:latest --reboot
```

[Go back to Table of Contents](#table-of-contents)

### Rebasing to `sukarn-ublue-budgie`

First rebase to the unsigned image, to get the proper signing keys and policies installed. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/sukarn-m/sukarn-ublue-budgie:latest --reboot
```

Then rebase to the signed image. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-budgie:latest --reboot
```

[Go back to Table of Contents](#table-of-contents)

### Pinning to a Specific Tag

This repository builds date tags as well, so if you want to rebase to a particular day's build:

`rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-laptop:20240701`

This repository by default also supports signing.

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

[Go back to Table of Contents](#table-of-contents)

---

## Secure Boot

To use these images with secure boot, you may need to manually install relevant certificates.

### Fedora's certificate

Download Fedora's certificate from [https://src.fedoraproject.org/rpms/shim-unsigned-x64/tree/rawhide](https://src.fedoraproject.org/rpms/shim-unsigned-x64/tree/rawhide) and save it to `/tmp/fedora-ca.cer`.

As of writing, the relevant file is located at `https://src.fedoraproject.org/rpms/shim-unsigned-x64/blob/rawhide/f/fedora-ca-20200709.cer`.

Automated method:
```bash
ujust sukarn-enroll-fedora-certificate
```

Manual method:
```bash
wget --output-document=/tmp/fedora-ca.cer https://src.fedoraproject.org/rpms/shim-unsigned-x64/blob/rawhide/f/fedora-ca-20200709.cer
sudo mokutil --timeout -1
sudo mokutil --import /tmp/fedora-ca.cer
sudo systemctl reboot
```

### Universal-Blue's certificate

The akmods key is located on the ublue-os based images at `/etc/pki/akmods/certs/akmods-ublue.der`.

Automated method:
```bash
ujust enroll-secure-boot-key
```

Manual method:
```bash
sudo mokutil --timeout -1
sudo mokutil --import /etc/pki/akmods/certs/akmods-ublue.der
sudo systemctl reboot
```

[Go back to Table of Contents](#table-of-contents)

---

## Encrypted Drives

TPM2 equipped devices can be set to automatically unlock encrypted drives.

### Enable Auto-Unlock Using TPM2

Images based on Universal-Blue builds can run the following command to enable auto-unlock using  TPM2:

```bash
ujust setup-luks-tpm-unlock
```

For manual steps, refer to [https://github.com/ublue-os/config/blob/main/build/ublue-os-luks/luks-enable-tpm2-autounlock](https://github.com/ublue-os/config/blob/main/build/ublue-os-luks/luks-enable-tpm2-autounlock).

### Disable Auto-Unlock Using TPM2

Images based on Universal-Blue builds can run the following command to enable auto-unlock using  TPM2:

```bash
ujust remove-luks-tpm-unlock
```

For manual steps, refer to [https://github.com/ublue-os/config/blob/main/build/ublue-os-luks/luks-disable-tpm2-autounlock](https://github.com/ublue-os/config/blob/main/build/ublue-os-luks/luks-disable-tpm2-autounlock).

[Go back to Table of Contents](#table-of-contents)

---

## Custom Commands

**Note:** To see a list of all custom commands available, run:

```bash
ujust --choose
```

These images contain custom commands from the universal-blue project, and custom commands added by the maintainer of this repository. List of custom commands added by the maintainer of this repository:

| Command                            | Purpose                                            |
| ---------------------------------- | -------------------------------------------------- |
| `sukarn-enable-nfs-cache`          | Enable NFS caching                                 |
| `sukarn-remove-nfs-cache`          | Remove NFS caching and cached files                |
| `sukarn-added-canon-lbp-2900`      | Add this printer to the printers list              |
| `sukarn-fix-grub-double-entry`     | Fix the grub double entries issue in Fedora Atomic |
| `sukarn-enroll-fedora-certificate` | Enroll the upstream fedora certificate             |
| `sukarn-grub-toggle-savedefault`   | Enable or disable GRUB_SAVEDEFAULT                 |

---

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso).

The `make-laptop-iso.sh` and `make-desktop-iso.sh` scripts can make ISOs using `podman`. The ISO is saved in `iso-output` directory. Run only one of these scripts at a time. They may overwrite each-other's output. See [JasonN3/build-container-installer](https://github.com/JasonN3/build-container-installer) for variables (must be specified in all caps).

The Action currently uses [ublue-os/isogenerator-old](https://github.com/ublue-os/isogenerator-old). The ISO is a netinstaller and should always pull the latest version of your image. Note that this release-iso action is not a replacement for a full-blown release automation like [release-please](https://github.com/googleapis/release-please).

[Go back to Table of Contents](#table-of-contents)

---

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/sukarn-m/sukarn-ublue
```

[Go back to Table of Contents](#table-of-contents)
