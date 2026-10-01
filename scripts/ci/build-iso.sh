#!/usr/bin/env bash
# CI: build the installer ISO from out/repo (the packages job's artifact),
# inside a throwaway archlinux container. mkarchiso needs root and mounts, so
# the container runs --privileged (see .github/workflows/build.yml).
#
# Local equivalent, from the repo root after `make repo`:
#   docker run --rm --privileged -v "$PWD:/src" -w /src archlinux:base-devel scripts/ci/build-iso.sh
set -euo pipefail

sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
pacman -Syu --noconfirm --needed archiso pacman-contrib git
git config --global --add safe.directory '*'

scripts/build-iso.sh
ls -la out/*.iso
