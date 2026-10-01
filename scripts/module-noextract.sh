#!/usr/bin/env bash
# Print pacman NoExtract lines that leave kernel module trees out of an image,
# along with every module that depends on one of them (build-iso.sh net).
#
#   module-noextract.sh LINUX_PKG GROUPS_FILE
#
# GROUPS_FILE lists paths under usr/lib/modules/<version>/kernel/, one per
# line (# comments allowed). Dependents come from modules.dep, which lists each
# module's full dependency closure. The package doesn't ship it (a pacman hook
# runs depmod), so this runs depmod on an extracted copy.
set -euo pipefail

[[ $# -eq 2 ]] || { sed -n '5s/^# //p' "$0" >&2; exit 1; }
pkg=$1 groups=$2

mapfile -t trees < <(sed 's/#.*//; s/[[:space:]]*$//; /^$/d' "$groups")
for tree in "${trees[@]}"; do
  if [[ $tree == *.ko ]]; then
    echo "NoExtract = usr/lib/modules/*/kernel/$tree*"
  else
    echo "NoExtract = usr/lib/modules/*/kernel/$tree/*"
  fi
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tar -C "$tmp" -xf "$pkg" usr/lib/modules
kver=$(basename "$tmp"/usr/lib/modules/*)
ln -s usr/lib "$tmp/lib"  # depmod -b looks in <base>/lib/modules
depmod -b "$tmp" "$kver"

awk -v trees="${trees[*]}" '
  BEGIN { nt = split(trees, t, " ") }
  function dropped(m,   i) {
    for (i = 1; i <= nt; i++)
      if (index(m, "kernel/" t[i]) == 1) return 1
    return 0
  }
  {
    sub(/:$/, "", $1)
    if (dropped($1)) next
    for (i = 2; i <= NF; i++)
      if (dropped($i)) { print "NoExtract = usr/lib/modules/*/" $1; next }
  }' "$tmp/usr/lib/modules/$kver/modules.dep"
