#!/usr/bin/env bash
# Build the AUR packages in aur.txt and the local packages under packages/ in a
# clean chroot, then collect them into a pacman repo at out/repo.
#
# Needs: devtools, git. Run as a normal user; makechrootpkg asks for sudo.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
work=$root/work
chroot=$work/chroot
repo=$root/out/repo
repo_name=couchbox

mkdir -p "$work/aur" "$repo"

if [[ ! -d $chroot/root ]]; then
  mkdir -p "$chroot"
  mkarchroot "$chroot/root" base-devel
fi
arch-nspawn "$chroot/root" pacman -Syu --noconfirm

# True if every package the PKGBUILD in the current directory would produce
# is already in the repo, so reruns skip finished builds.
built() {
  local f
  for f in $(makepkg --packagelist); do
    [[ ${f##*/} == *-debug-* || -e $repo/${f##*/} ]] || return 1
  done
}

# collect: move fresh packages into the repo. Debug packages are dropped to
# keep the ISO small.
collect() {
  rm -f ./*-debug-*.pkg.tar.zst
  mv ./*.pkg.tar.zst "$repo/"
}

# build_chroot <dir> [<local dep>...]: clean-chroot build, for AUR packages.
build_chroot() {
  local dir=$1 dep pkgs=() installs=()
  shift
  for dep; do
    pkgs=("$repo/$dep"-[0-9]*.pkg.tar.zst)
    [[ -e ${pkgs[0]} ]] || { echo "missing local dependency: $dep" >&2; exit 1; }
    installs+=(-I "${pkgs[-1]}")
  done
  (
    cd "$dir"
    built && { echo "==> $dir: up to date"; exit 0; }
    rm -f ./*.pkg.tar.zst
    makechrootpkg -c -r "$chroot" "${installs[@]}"
    collect
  )
}

# build_local <dir>: config-only packages such as couchbox-base depend on the
# AUR builds, which the chroot can't resolve. Build them without dependency
# checks; they have nothing to compile.
build_local() {
  (
    cd "$1"
    built && { echo "==> $1: up to date"; exit 0; }
    rm -f ./*.pkg.tar.zst
    makepkg --nodeps --cleanbuild --force
    collect
  )
}

while read -r name deps; do
  [[ -z $name || $name == \#* ]] && continue
  if [[ -d $work/aur/$name/.git ]]; then
    git -C "$work/aur/$name" pull --ff-only
  else
    git clone "https://aur.archlinux.org/$name.git" "$work/aur/$name"
  fi
  # shellcheck disable=SC2086  # deps is a space-separated list
  build_chroot "$work/aur/$name" $deps
done < "$root/aur.txt"

# fire-blaster has no releases to download: pack its working tree as the
# package source, versioned by its newest file so pacman sees each change.
fb_src=${FIRE_BLASTER_SRC:-$root/../fire-blaster}
fb_pkg=$root/packages/fire-blaster
if [[ -d $fb_pkg ]]; then
  [[ -d $fb_src/src/fireblaster ]] || { echo "fire-blaster source not found at $fb_src (set FIRE_BLASTER_SRC)" >&2; exit 1; }
  find "$fb_src"/{src,profiles,systemd,udev,desktop} "$fb_src"/{pyproject.toml,config.example.toml} \
    -type f -not -path '*/__pycache__/*' -printf '%T@\n' | sort -n | tail -1 | cut -d. -f1 > "$fb_pkg/srcstamp"
  tar -C "$(dirname "$fb_src")" -czf "$fb_pkg/fire-blaster-src.tar.gz" \
    --exclude=.venv --exclude=.cache --exclude=.pytest_cache --exclude=__pycache__ --exclude='*.egg-info' \
    --transform "s|^$(basename "$fb_src")|fire-blaster|" "$(basename "$fb_src")"
fi

# Packages that compile something (have a build() function) need the clean
# chroot; config-only packages are built locally.
for dir in "$root"/packages/*/; do
  if grep -q '^build()' "$dir/PKGBUILD"; then
    build_chroot "$dir"
  else
    build_local "$dir"
  fi
done

# Drop superseded versions and rebuild the database from what is left.
rm -f "$repo/$repo_name".{db,files}*
paccache -rk1 -c "$repo"
repo-add "$repo/$repo_name.db.tar.zst" "$repo"/*.pkg.tar.zst
