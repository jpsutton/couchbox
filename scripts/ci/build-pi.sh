#!/usr/bin/env bash
# CI: build the aarch64 couchbox repo and a Raspberry Pi test image, inside an
# Arch Linux ARM container on an arm64 runner (.github/workflows/rpi.yml).
# Runs as root; builds packages as an unprivileged user with passwordless
# sudo for pacman, as makepkg requires (same as build-packages.sh).
#
# Output: out/repo (couchbox-aarch64.db and its packages, the arch=any ones
# included) and out/couchbox-rpi-test.img.xz.
set -euo pipefail

src=$PWD

echo "==> Arch Linux ARM container setup"
pacman-key --init
pacman-key --populate archlinuxarm
sed -i -e 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' -e 's/^CheckSpace/#CheckSpace/' /etc/pacman.conf
# The generic rootfs carries a mainline kernel a container never boots.
pacman -Rdd --noconfirm linux-aarch64 2>/dev/null || true
pacman -Syu --noconfirm --needed base-devel git sudo pacman-contrib arch-install-scripts dosfstools e2fsprogs xz

id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(root) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder
chown -R builder: "$src" "${FIRE_BLASTER_SRC:?set FIRE_BLASTER_SRC to the fire-blaster checkout}"

# mpv's release tags are signed (validpgpkeys in packages/mpv-rpi).
su builder -c 'gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys 145077D82501AA20152CACCE8D769208D5E31419'

# ffmpeg-rpi has under-declared its dependencies before (sndio, which
# mpv-rpi now depends on); list any library its shared objects can't find.
pacman -S --noconfirm --needed ffmpeg-rpi sndio
for lib in /usr/lib/lib{avcodec,avdevice,avfilter,avformat,avutil,postproc,swresample,swscale}.so.*.*; do
  ldd "$lib" | grep 'not found' | sed "s|^|$lib: |" || true
done

su builder -c "git config --global --add safe.directory '*' && COUCHBOX_BUILD=container FIRE_BLASTER_SRC='$FIRE_BLASTER_SRC' scripts/build-repo.sh"
ls -la out/repo

echo "==> Image"
# mpv-rpi by name: otherwise Ember's and couchbox-iptv's mpv dependency
# pulls in the stock mpv, which can't use the Pi's HEVC decoder.
scripts/build-pi-image.sh -x scripts/ci/pi-test-hook.sh out/repo out/couchbox-rpi-test.img \
  couchbox-base couchbox-rpi mpv-rpi
xz -T0 -6 -f out/couchbox-rpi-test.img
ls -la out/
