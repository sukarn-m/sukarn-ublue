# sukarn-ublue

[![build-ublue](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build.yml/badge.svg)](https://github.com/sukarn-m/sukarn-ublue/actions/workflows/build.yml)

This is a constantly updating repository for creating [a native container image](https://fedoraproject.org/wiki/Changes/OstreeNativeContainerStable) designed to be customized.

For more info, check out the [uBlue homepage](https://universal-blue.org/) and the [main uBlue repo](https://github.com/ublue-os/main/)

## Getting started

See the [Make Your Own-page in the documentation](https://universal-blue.org/tinker/make-your-own/) for quick setup instructions for setting up your own repository based on this template.

## Customization

The easiest way to start customizing is by looking at and modifying `config/recipe.yml`. It's documented using comments and should be pretty easy to understand.

If you want to add custom configuration files, you can just add them in the `/usr/etc/` directory, which is the official OSTree "configuration template" directory and will be applied to `/etc/` on boot. `config/files/usr` is copied into your image's `/usr` by default. If you need to add other directories in the root of your image, that can be done using the `files` module. Writing to `/var/` in the image builds of OSTree-based distros isn't supported and will not work, as that is a local user-managed directory!

For more information about customization, see [the README in the config directory](config/README.md)

Documentation around making custom images exists / should be written in two separate places:
* [The Tinkerer's Guide on the website](https://universal-blue.org/tinker/make-your-own/) for general documentation around making custom images, best practices, tutorials, and so on.
* Inside this repository for documentation specific to the ins and outs of the template (like module documentation), and just some essential guidance on how to make custom images.

## Installation by rebasing from Silverblue

> **Warning**
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable) and should not be used in production, try it in a VM for a while!

To rebase an existing Silverblue installation to the latest build:

| Step Number | Description | Desktop | Laptop |
| :---------: | ---------- | ------- | ------ |
| 1 | First rebase to the unsigned image, to get the proper signing keys and policies installed | `rpm-ostree rebase ostree-unverified-registry:ghcr.io/sukarn-m/sukarn-ublue-desktop:latest` | `rpm-ostree rebase ostree-unverified-registry:ghcr.io/sukarn-m/sukarn-ublue-laptop:latest` |
| 2 | Reboot to complete the rebase | `systemctl reboot` | `systemctl reboot` |
| 3 | Then rebase to the signed image | `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-desktop:latest` | `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-laptop:latest` |
| 4 | Reboot again to complete the installation | `systemctl reboot` | `systemctl reboot` |

### Installation - Additional information

This repository builds date tags as well, so if you want to rebase to a particular day's build:

`rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sukarn-m/sukarn-ublue-laptop:20230403`

This repository by default also supports signing.

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

This template includes a simple Github Action to build and release an ISO of your image. 

To run the action, simply edit the `boot_menu.yml` by changing all the references to startingpoint to your repository. This should trigger the action automatically.

The Action uses [isogenerator](https://github.com/ublue-os/isogenerator) and works in a similar manner to the official Universal Blue ISO. If you have any issues, you should first check [the documentation page on installation](https://universal-blue.org/installation/). The ISO is a netinstaller and should always pull the latest version of your image.

Note that this release-iso action is not a replacement for a full-blown release automation like [release-please](https://github.com/googleapis/release-please).

## `just`

The [`just`](https://just.systems/) command runner is included in all `ublue-os/main`-derived images.

You need to have a `~/.justfile` with the following contents and `just` aliased to `just --unstable` (default in posix-compatible shells on ublue) to get started with just locally.
```
!include /usr/share/ublue-os/just/main.just
!include /usr/share/ublue-os/just/nvidia.just
!include /usr/share/ublue-os/just/custom.just
```
Then type `just` to list the just recipes available.

The file `/usr/share/ublue-os/just/custom.just` is intended for the custom just commands (recipes) you wish to include in your image. By default, it includes the justfiles from [`ublue-os/bling`](https://github.com/ublue-os/bling), if you wish to disable that, you need to just remove the line that includes bling.just.

See [the just-page in the Universal Blue documentation](https://universal-blue.org/guide/just/) for more information.
