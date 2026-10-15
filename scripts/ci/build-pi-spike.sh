#!/usr/bin/env bash
# CI (spike): build the aarch64 packages the Raspberry Pi spike needs and a
# flashable test image, inside an Arch Linux ARM container on an arm64 runner
# (see .github/workflows/rpi-spike.yml). Runs as root; builds packages as an
# unprivileged user, as makepkg requires.
#
# The spike image is not couchbox yet: Plasma Bigscreen, Ember, mpv-rpi and
# Chromium for YouTube, to measure KWin and hardware decode on a Pi 4 before
# the real port. Output: out/pi/ (repo) and out/couchbox-rpi-spike.img.xz.
set -euo pipefail

src=$PWD
repo=$src/out/pi

echo "==> Arch Linux ARM container setup"
pacman-key --init
pacman-key --populate archlinuxarm
sed -i -e 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' -e 's/^CheckSpace/#CheckSpace/' /etc/pacman.conf
# The generic rootfs carries a mainline kernel a container never boots.
pacman -Rdd --noconfirm linux-aarch64 2>/dev/null || true
pacman -Syu --noconfirm --needed base-devel git sudo arch-install-scripts dosfstools e2fsprogs xz

id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(root) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder
chown -R builder: "$src"
mkdir -p "$repo"
chown builder: "$repo"

# mpv's release tags are signed (validpgpkeys in packages/mpv-rpi).
su builder -c 'gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys 145077D82501AA20152CACCE8D769208D5E31419'
su builder -c "git config --global --add safe.directory '*'"

# build <dir>: makepkg -s as builder; the packages land in $repo.
build() {
  echo "==> Build $1"
  su builder -c "cd '$src/packages/$1' && PKGDEST='$repo' makepkg -s --noconfirm --needed"
}

# ffmpeg-rpi has under-declared its dependencies before (sndio); list any
# library its shared objects can't find, so the log says what to add.
pacman -S --noconfirm --needed ffmpeg-rpi
for lib in /usr/lib/lib{avcodec,avdevice,avfilter,avformat,avutil,postproc,swresample,swscale}.so.*.*; do
  ldd "$lib" | grep 'not found' | sed "s|^|$lib: |" || true
done

# Arch Linux ARM's makepkg.conf picks its own PKGEXT (.pkg.tar.xz), so
# globs below match any compression.
build mpv-rpi
# Ember depends on mpv; install mpv-rpi first so makepkg -s doesn't pull
# the stock mpv.
ls -la "$repo"
pacman -U --noconfirm "$repo"/mpv-rpi-[0-9]*.pkg.tar.*
build ember
build couchbox-rpi

rm -f "$repo"/*-debug-*.pkg.tar.*
repo-add "$repo/couchbox-aarch64.db.tar.zst" "$repo"/*.pkg.tar.*

echo "==> Image"
spike_packages=(
  couchbox-rpi mpv-rpi ember
  # The Bigscreen session (as couchbox-base pulls in)
  plasma-bigscreen plasma-nm plasma-pa kscreen powerdevil xdg-desktop-portal-kde sddm
  networkmanager bluez bluez-utils libcec pipewire pipewire-pulse wireplumber
  noto-fonts konsole zerotier-one
  # YouTube in Chromium (the plan for aarch64)
  chromium
  # Measuring
  mesa-utils htop iw
)
scripts/build-pi-image.sh -x scripts/ci/pi-spike-hook.sh "$repo" out/couchbox-rpi-spike.img "${spike_packages[@]}"
xz -T0 -6 -f out/couchbox-rpi-spike.img
ls -la out/
