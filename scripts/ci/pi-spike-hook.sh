#!/usr/bin/env bash
# build-pi-image.sh hook for the spike image: what couchbox-base would set up
# (autologin into Bigscreen, services), plus a YouTube tile on Chromium.
set -euo pipefail
root=${1:?usage: pi-spike-hook.sh <mounted root>}
src=$(cd "$(dirname "$0")/../.." && pwd)

install -Dm644 "$src/packages/couchbox-base/sddm-couchbox.conf" "$root/etc/sddm.conf.d/couchbox.conf"

# YouTube's TV interface in Chromium, with V4L2 decode asked for. The flags
# are what the spike measures; chrome://gpu shows what took effect.
install -Dm755 /dev/stdin "$root/usr/local/bin/couchbox-youtube-chromium" <<'SH'
#!/bin/sh
exec chromium \
  --user-data-dir="$HOME/.local/share/couchbox-youtube-chromium" \
  --class=couchbox-youtube-chromium \
  --ozone-platform=wayland \
  --enable-features=AcceleratedVideoDecoder,AcceleratedVideoDecodeLinuxGL \
  --user-agent='Mozilla/5.0 (Web0S; Linux/SmartTV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.270 Safari/537.36 WebAppManager' \
  --start-fullscreen --no-first-run --noerrdialogs \
  --app=https://www.youtube.com/tv "$@"
SH
install -Dm644 /dev/stdin "$root/usr/local/share/applications/couchbox-youtube-chromium.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=YouTube (Chromium)
Comment=YouTube's TV interface in Chromium, Pi spike
Exec=couchbox-youtube-chromium
Icon=chromium
Categories=AudioVideo;Video;Player;
StartupWMClass=couchbox-youtube-chromium
DESKTOP

arch-chroot "$root" systemctl enable sddm.service NetworkManager.service bluetooth.service systemd-timesyncd.service
# The spike is for SSH measurements; couchbox-setup.txt still has to set a
# password or key before anyone can log in.
arch-chroot "$root" systemctl enable sshd.service
