# sukarn-ublue

[![build-gnome](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build-gnome.yml/badge.svg)](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build-gnome.yml) [![build-budgie](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build-budgie.yml/badge.svg)](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build-budgie.yml)

This is a constantly updating repository for creating [a native container image](https://fedoraproject.org/wiki/Changes/OstreeNativeContainerStable) designed to be customized.

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

### Rebasing to `sukarn-ublue-laptop`

First rebase to the unsigned image, to get the proper signing keys and policies installed. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/sukarn-m/sukarn-ublue-laptop:latest --reboot
```

Then rebase to the signed image. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-laptop:latest --reboot
```

### Rebasing to `sukarn-ublue-budgie`

First rebase to the unsigned image, to get the proper signing keys and policies installed. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/sukarn-m/sukarn-ublue-budgie:latest --reboot
```

Then rebase to the signed image. The system will reboot automatically upon completion of this step.

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-budgie:latest --reboot
```

### Installation - Additional information

This repository builds date tags as well, so if you want to rebase to a particular day's build:

`rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-laptop:20240701`

This repository by default also supports signing.

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso).

The `make-laptop-iso.sh` and `make-desktop-iso.sh` scripts can make ISOs using `podman`. The ISO is saved in `iso-output` directory. Run only one of these scripts at a time. They may overwrite each-other's output. See [JasonN3/build-container-installer](https://github.com/JasonN3/build-container-installer) for variables (must be specified in all caps).

The Action currently uses [ublue-os/isogenerator-old](https://github.com/ublue-os/isogenerator-old). The ISO is a netinstaller and should always pull the latest version of your image. Note that this release-iso action is not a replacement for a full-blown release automation like [release-please](https://github.com/googleapis/release-please).

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/sukarn-m/sukarn-ublue
```

# Based on BlueBuild Template

See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for quick setup instructions for setting up your own repository based on this template.
