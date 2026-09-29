#!/usr/bin/env bash
# Build the couchbox installer ISO: the stock archiso releng profile, plus the
# files under iso/ and a copy of the local repo from scripts/build-repo.sh.
#
# Needs: archiso. Run as root (mkarchiso requires it).
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
arch=$(uname -m)
profile=$root/work/profile
repo=$root/out/repo

[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -e $repo/couchbox.db ]] || { echo "no repo at $repo; run scripts/build-repo.sh first" >&2; exit 1; }

rm -rf "$profile" "$root/work/iso"
cp -r /usr/share/archiso/configs/releng "$profile"
cp -rT "$root/iso/airootfs" "$profile/airootfs"
cat "$root/iso/packages.$arch" >> "$profile/packages.$arch"

# The installer pacstraps from this copy, so the ISO carries the AUR builds.
mkdir -p "$profile/airootfs/var/lib/couchbox"
cp -r "$repo" "$profile/airootfs/var/lib/couchbox/repo"

sed -i \
  -e 's/^iso_name=.*/iso_name="couchbox"/' \
  -e 's/^iso_label=.*/iso_label="COUCHBOX_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
  -e 's/^iso_publisher=.*/iso_publisher="couchbox"/' \
  -e 's/^iso_application=.*/iso_application="couchbox installer"/' \
  -e 's|^file_permissions=(|&\n  ["/usr/local/bin/couchbox-install"]="0:0:755"|' \
  "$profile/profiledef.sh"

mkarchiso -v -w "$root/work/iso" -o "$root/out" "$profile"
