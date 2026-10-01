#!/usr/bin/env bash
# CI: build an installer ISO inside a throwaway archlinux container. The full
# ISO (no argument) is built from out/repo, the packages job's artifact; the
# netinstall ISO (`net`) needs no packages. mkarchiso needs root and mounts, so
# the container runs --privileged (see .github/workflows/build.yml).
#
# Local equivalent, from the repo root (after `make repo` for the full ISO):
#   docker run --rm --privileged -v "$PWD:/src" -w /src archlinux:base-devel scripts/ci/build-iso.sh [net]
set -euo pipefail

sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
pacman -Syu --noconfirm --needed archiso pacman-contrib grub git
git config --global --add safe.directory '*'

scripts/build-iso.sh "$@"
ls -la out/*.iso
