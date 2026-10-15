#!/usr/bin/env bash
# build-pi-image.sh hook for CI test images: SSH on from the first boot, for
# measuring on the Pi. couchbox-setup.txt still has to set a password or key
# before anyone can log in.
set -euo pipefail
root=${1:?usage: pi-test-hook.sh <mounted root>}
arch-chroot "$root" systemctl enable sshd.service
