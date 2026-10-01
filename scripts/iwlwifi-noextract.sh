#!/usr/bin/env bash
# Print pacman NoExtract lines for the iwlwifi firmware a kernel won't load,
# or doesn't need (build-iso.sh net uses them for the live system).
#
#   iwlwifi-noextract.sh IWLWIFI_KO FIRMWARE_PKG
#
# linux-firmware-intel ships several firmware API versions per chip (96 MiB).
# The driver tries the newest version it supports, then older ones. Keep the
# two newest that each chip can use. The cap is the version the module
# declares (modinfo) for that chip, else the highest it declares in that
# series (plain numbers, or the newer cNNN). Firmware newer than the kernel
# goes too.
set -euo pipefail

[[ $# -eq 2 ]] || { sed -n '5s/^# //p' "$0" >&2; exit 1; }
ko=$1 pkg=$2

# "<chip> x|xc <version> <file>": xc is the cNNN series.
fwver='s/^(iwlwifi-.*)-(c?)([0-9]+)(\.ucode.*)$/\1 x\2 \3 &/p'
{
  modinfo -F firmware "$ko" | sed -nE "$fwver" |
    awk '{ print "cap", $1, ($2 == "xc"), $3 }'
  tar -tf "$pkg" | sed -n 's|^usr/lib/firmware/intel/iwlwifi/||p' | sed -nE "$fwver" |
    awk '{ print "file", $1, ($2 == "xc"), $3, $4 }'
} | sort -k1,1 -k2,2 -k3,3n -k4,4n | awk '
  $1 == "cap" {
    cap[$2] = $3 * 10000 + $4
    if (cap[$2] > series[$3]) series[$3] = cap[$2]
    next
  }
  {
    key = $3 * 10000 + $4
    limit = ($2 in cap) ? cap[$2] : series[$3]
    if (key > limit) drop[++nd] = $5
    else usable[$2, ++n[$2]] = $5
  }
  END {
    for (chip in n)
      for (i = 1; i <= n[chip] - 2; i++) drop[++nd] = usable[chip, i]
    for (i = 1; i <= nd; i++)
      printf "NoExtract = usr/lib/firmware/intel/iwlwifi/%s usr/lib/firmware/%s\n", drop[i], drop[i]
  }' | sort
