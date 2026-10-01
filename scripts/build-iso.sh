#!/usr/bin/env bash
# Build the couchbox installer ISO from the archiso releng profile, with:
#   - a minimal live environment (iso/packages.x86_64), UEFI boot only
#   - an offline repo holding everything couchbox-install puts on a target
#     (iso/target-packages plus all dependencies), so installs need no network
#   - the couchbox repo from scripts/build-repo.sh, copied to the target for
#     later updates
#
# Needs: archiso, pacman-contrib. Run as root (mkarchiso requires it).
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
arch=$(uname -m)
work=$root/work
profile=$work/profile
repo=$root/out/repo
offline=$work/offline

[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -e $repo/couchbox.db ]] || { echo "no repo at $repo; run scripts/build-repo.sh first" >&2; exit 1; }

mkdir -p "$work"
rm -rf "$profile" "$work/iso"
cp -r /usr/share/archiso/configs/releng "$profile"
cp -rT "$root/iso/airootfs" "$profile/airootfs"
cp "$root/iso/packages.$arch" "$profile/packages.$arch"

# releng enables services for packages the minimal live environment drops.
sysd=$profile/airootfs/etc/systemd/system
rm -rf "$sysd/cloud-init.target.wants" \
  "$sysd/sound.target.wants" \
  "$sysd/choose-mirror.service" \
  "$sysd/livecd-alsa-unmuter.service" \
  "$sysd/livecd-talk.service" \
  "$sysd/dbus-org.freedesktop.ModemManager1.service"
for unit in choose-mirror hv_fcopy_daemon hv_kvp_daemon hv_vss_daemon iwd \
  livecd-talk ModemManager vboxservice vmtoolsd; do
  rm -f "$sysd/multi-user.target.wants/$unit.service"
done

# Offline repo: download the union of every set in target-packages, with all
# dependencies, by resolving against an empty package database.
mapfile -t targets < <(sed -n 's/^[a-z]*: *//p' "$root/iso/target-packages" | tr ' ' '\n' | sed '/^$/d' | sort -u)
rm -rf "$offline"
mkdir -p "$offline"
dbpath=$(mktemp -d)
trap 'rm -rf "$dbpath"' EXIT
cat > "$work/offline-pacman.conf" <<EOF
[options]
Architecture = auto
DBPath = $dbpath
CacheDir = $offline
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[couchbox]
SigLevel = Optional TrustAll
Server = file://$repo
EOF
pacman --config "$work/offline-pacman.conf" -Syw --noconfirm "${targets[@]}"
# pacman uses file:// packages in place instead of caching them.
cp -n "$repo"/*.pkg.tar.zst "$offline/"
repo-add -q "$offline/couchbox-offline.db.tar.zst" "$offline"/*.pkg.tar.zst
echo "offline repo: $(ls "$offline"/*.pkg.tar.zst | wc -l) packages, $(du -sh "$offline" | cut -f1)"

lib=$profile/airootfs/var/lib/couchbox
mkdir -p "$lib" "$profile/airootfs/etc/couchbox"
cp -r "$repo" "$lib/repo"
cp -r "$offline" "$lib/offline"
cp "$root/iso/target-packages" "$profile/airootfs/etc/couchbox/target-packages"

# The offline repo is already zstd-compressed, so xz buys nothing but build
# time; zstd keeps the image quick to build and to read.
sed -i -z \
  -e 's/iso_name="[^"]*"/iso_name="couchbox"/' \
  -e 's/iso_publisher="[^"]*"/iso_publisher="couchbox"/' \
  -e 's/iso_application="[^"]*"/iso_application="couchbox installer"/' \
  -e "s/bootmodes=([^)]*)/bootmodes=('uefi.systemd-boot')/" \
  -e "s/airootfs_image_tool_options=([^)]*)/airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')/" \
  -e 's|file_permissions=(|&\n  ["/usr/local/bin/couchbox-install"]="0:0:755"|' \
  "$profile/profiledef.sh"
sed -i 's/^iso_label=.*/iso_label="COUCHBOX_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
  "$profile/profiledef.sh"

mkarchiso -v -w "$work/iso" -o "$root/out" "$profile"
