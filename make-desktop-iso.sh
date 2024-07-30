#!/bin/bash

# From: https://blue-build.org/learn/universal-blue/

mkdir -p ./iso-output
sudo podman run --rm --privileged --volume ./iso-output:/build-container-installer/build --security-opt label=disable --pull=newer \
ghcr.io/jasonn3/build-container-installer:latest \
VERSION=39 \
IMAGE_REPO=ghcr.io/sukarn-m \
IMAGE_NAME=sukarn-ublue-desktop \
IMAGE_TAG=latest \
ISO_NAME=build/sukarn-ublue-desktop.iso \
VARIANT=Silverblue # should match the variant your image is based on
