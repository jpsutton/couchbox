#!/usr/bin/env bash
# CI: build every couchbox package into out/repo, inside a throwaway
# archlinux:base-devel container (see .github/workflows/build.yml). Runs as
# root; builds as an unprivileged user with passwordless sudo for pacman, as
# makepkg requires.
#
# Local equivalent, from the repo root:
#   docker run --rm -v "$PWD:/src" -v "$PWD/../fire-blaster:/fire-blaster" \
#     -e FIRE_BLASTER_SRC=/fire-blaster -w /src archlinux:base-devel scripts/ci/build-packages.sh
set -euo pipefail

pacman -Syu --noconfirm --needed git pacman-contrib sudo

id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(root) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder
chown -R builder: "$PWD" "${FIRE_BLASTER_SRC:?set FIRE_BLASTER_SRC to the fire-blaster checkout}"

# Parallel downloads: the Flutter, Electron and KDE build dependencies are big.
sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf

su builder -c "git config --global --add safe.directory '*' && COUCHBOX_BUILD=container FIRE_BLASTER_SRC='$FIRE_BLASTER_SRC' scripts/build-repo.sh"
ls -la out/repo
