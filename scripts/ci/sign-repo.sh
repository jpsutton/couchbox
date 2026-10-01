#!/usr/bin/env bash
# CI (release): sign a built repo for publishing as GitHub release assets.
#   sign-repo.sh <repo dir>
# Needs COUCHBOX_GPG_KEY (the armored private key; the release workflow passes
# the repo secret). Writes a detached .sig per package, rebuilds couchbox.db
# signed, and turns the database symlinks into plain files, since release
# assets can't be symlinks. Runs in an archlinux container (repo-add).
set -euo pipefail
dir=${1:?repo dir}
: "${COUCHBOX_GPG_KEY:?COUCHBOX_GPG_KEY is not set}"

pacman -Sy --noconfirm --needed gnupg >/dev/null
export GNUPGHOME
GNUPGHOME=$(mktemp -d)
trap 'gpgconf --kill all; rm -rf "$GNUPGHOME"' EXIT
gpg --batch --quiet --import <<<"$COUCHBOX_GPG_KEY"
fpr=$(gpg --batch --with-colons --list-secret-keys | awk -F: '/^fpr/ {print $10; exit}')
echo "signing with $fpr"

cd "$dir"
rm -f ./*.sig couchbox.db* couchbox.files*
for pkg in ./*.pkg.tar.zst; do
  gpg --batch --yes --detach-sign --no-armor "$pkg"
done
repo-add --sign --key "$fpr" couchbox.db.tar.zst ./*.pkg.tar.zst
for link in couchbox.db couchbox.db.sig couchbox.files couchbox.files.sig; do
  [[ -L $link ]] && cp --remove-destination "$(readlink -f "$link")" "$link"
done
# Prove it: every signature verifies against the imported key.
for sig in ./*.sig; do
  gpg --batch --quiet --verify "$sig" "${sig%.sig}"
done
ls -la
