#!/usr/bin/env bash
# Build a couchbox installer ISO from the archiso releng profile. Both
# variants have a minimal live environment (iso/packages.x86_64), UEFI boot
# only, and the same couchbox-install.
#
#   build-iso.sh [full]   out/couchbox-*.iso. Adds an offline repo holding
#                         everything couchbox-install puts on a target
#                         (iso/target-packages plus all dependencies, the
#                         couchbox repo from scripts/build-repo.sh included),
#                         so installs need no network.
#   build-iso.sh net      out/couchbox-net-*.iso. No offline repo: the
#                         installer downloads the target from Arch's mirrors
#                         and the signed couchbox repo on GitHub releases.
#                         Adds Wi-Fi (iwd) and network firmware
#                         (iso/packages-net.x86_64). Needs no package build.
#
# Installed boxes update couchbox packages from the signed repo on GitHub
# releases either way.
#
# Needs: archiso, pacman-contrib, and grub for the netinstall ISO. Run as root
# (mkarchiso requires it).
set -euo pipefail

variant=${1:-full}
[[ $variant == full || $variant == net ]] || { echo "usage: $0 [full|net]" >&2; exit 1; }

root=$(cd "$(dirname "$0")/.." && pwd)
arch=$(uname -m)
work=$root/work
repo=$root/out/repo
offline=$work/offline
if [[ $variant == full ]]; then
  profile=$work/profile iso_work=$work/iso iso_name=couchbox bootmode=uefi.systemd-boot
else
  # GRUB reads the kernel and initramfs from the ISO 9660 file system.
  # systemd-boot can't, so mkarchiso would also copy both (about 50 MiB) into
  # the EFI partition.
  profile=$work/profile-net iso_work=$work/iso-net iso_name=couchbox-net bootmode=uefi.grub
fi

[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ $variant == net || -e $repo/couchbox.db ]] || { echo "no repo at $repo; run scripts/build-repo.sh first" >&2; exit 1; }

mkdir -p "$work"
rm -rf "$profile" "$iso_work"
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
units=(choose-mirror hv_fcopy_daemon hv_kvp_daemon hv_vss_daemon livecd-talk
  ModemManager vboxservice vmtoolsd)
[[ $variant == net ]] || units+=(iwd)
for unit in "${units[@]}"; do
  rm -f "$sysd/multi-user.target.wants/$unit.service"
done

mkdir -p "$profile/airootfs/etc/couchbox"
cp "$root/iso/target-packages" "$profile/airootfs/etc/couchbox/target-packages"

if [[ $variant == net ]]; then
  cp -rT "$root/iso/airootfs-net" "$profile/airootfs"
  cat "$root/iso/packages-net.$arch" >> "$profile/packages.$arch"
  # couchbox's signing key, to check the downloaded couchbox packages:
  # releng's pacman-init.service populates every keyring in this directory.
  install -Dm644 -t "$profile/airootfs/usr/share/pacman/keyrings" \
    "$root"/packages/couchbox-keyring/couchbox{.gpg,-trusted,-revoked}
  # Firmware the live system has no use for, kept out of the image through
  # the profile's pacman.conf (iso/net-noextract.conf says what and why).
  noextract=$work/net-noextract.conf
  cp "$root/iso/net-noextract.conf" "$noextract"
  # Kernel modules for hardware the installer never uses (iso/net-drop-modules),
  # and older iwlwifi firmware versions. Both helper scripts read the packages
  # from the cache mkarchiso installs from.
  pacman -Sw --noconfirm linux linux-firmware-intel >/dev/null
  cache=$(pacman-conf CacheDir | head -n1)
  kpkg=$cache/$(basename "$(pacman -Sp linux)")
  "$root/scripts/module-noextract.sh" "$kpkg" "$root/iso/net-drop-modules" > "$work/module-noextract.conf"
  echo "modules: leaving out $(wc -l < "$work/module-noextract.conf") trees and dependent modules"
  cat "$work/module-noextract.conf" >> "$noextract"
  ko=$(mktemp -d)
  tar -C "$ko" -xf "$kpkg" --wildcards 'usr/lib/modules/*/iwlwifi/iwlwifi.ko*'
  "$root/scripts/iwlwifi-noextract.sh" "$ko"/usr/lib/modules/*/kernel/drivers/net/wireless/intel/iwlwifi/iwlwifi.ko* \
    "$cache/$(basename "$(pacman -Sp linux-firmware-intel)")" > "$work/iwlwifi-noextract.conf"
  rm -rf "$ko"
  echo "iwlwifi: leaving out $(wc -l < "$work/iwlwifi-noextract.conf") firmware versions"
  cat "$work/iwlwifi-noextract.conf" >> "$noextract"
  sed -i "/^\[options\]/r $noextract" "$profile/pacman.conf"
  # Boot menu: name the entries for couchbox, and boot sooner.
  sed -i 's/Arch Linux install medium/couchbox network installer/; s/^timeout=15$/timeout=5/' \
    "$profile"/grub/*.cfg
else
  # Offline repo: download the union of every set in target-packages, with
  # all dependencies, by resolving against an empty package database.
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
  mkdir -p "$lib"
  cp -r "$offline" "$lib/offline"
fi

# The offline repo and firmware are already zstd-compressed, so xz buys
# nothing but build time; zstd keeps the image quick to build and to read.
sed -i -z \
  -e "s/iso_name=\"[^\"]*\"/iso_name=\"$iso_name\"/" \
  -e 's/iso_publisher="[^"]*"/iso_publisher="couchbox"/' \
  -e 's/iso_application="[^"]*"/iso_application="couchbox installer"/' \
  -e "s/bootmodes=([^)]*)/bootmodes=('$bootmode')/" \
  -e "s/airootfs_image_tool_options=([^)]*)/airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')/" \
  -e 's|file_permissions=(|&\n  ["/usr/local/bin/couchbox-install"]="0:0:755"|' \
  "$profile/profiledef.sh"
sed -i 's/^iso_label=.*/iso_label="COUCHBOX_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
  "$profile/profiledef.sh"

mkarchiso -v -w "$iso_work" -o "$root/out" "$profile"
