#!/usr/bin/env bash
# Build a couchbox SD-card image for the Raspberry Pi (Pi 4 and newer; Pi 3
# best effort) from Arch Linux ARM plus a local repo of couchbox packages.
#
#   scripts/build-pi-image.sh [-x <hook>] <repo dir> <output.img> <package>...
#
# <repo dir> holds couchbox-aarch64.db (scripts/build-repo.sh on aarch64).
# The image gets <package>... plus the base system, nothing else.
# -x <hook>: a script run after install with the mounted root as $1, for
# extra setup (the spike image uses it).
#
# Runs as root on an Arch Linux ARM system (a Pi, or the aarch64 CI
# container), or on x86_64 Arch with qemu-user-static-binfmt. Needs
# arch-install-scripts, dosfstools, e2fsprogs and util-linux.
#
# No partitioned loop devices: the boot (FAT) and root (ext4) filesystems are
# built as separate files and copied into the image at their partition
# offsets, which also works inside a container without udev.
#
# Layout: MBR (Pi 3 and older can't boot GPT), 512 MiB FAT32 /boot as
# partition 1 (the firmware reads config.txt and the kernel from it), ext4
# root as partition 2. The root filesystem is shrunk to its contents plus a
# little slack; couchbox-growfs fills the card on the first boot.
set -euo pipefail

hook=
while getopts x: opt; do
  case $opt in
    x) hook=$(realpath "$OPTARG") ;;
    *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))
(($# >= 3)) || { echo "usage: $0 [-x <hook>] <repo dir> <output.img> <package>..." >&2; exit 2; }
repo=$(realpath "$1") out=$(realpath -m "$2")
shift 2
packages=("$@")

[[ $(id -u) == 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -e $repo/couchbox-aarch64.db ]] || { echo "no couchbox-aarch64.db in $repo" >&2; exit 1; }

boot_mib=512
# Room to install into; shrunk afterwards.
root_build_mib=12288
root_slack_mib=512
align_sectors=8192   # partitions start on 4 MiB boundaries

work=$(mktemp -d "${TMPDIR:-/var/tmp}/couchbox-pi.XXXXXX")
mnt=$work/root
cleanup() {
  umount -R "$mnt" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

echo "==> Filesystems"
truncate -s "${root_build_mib}M" "$work/root.ext4"
mkfs.ext4 -q -L couchbox "$work/root.ext4"
truncate -s "${boot_mib}M" "$work/boot.vfat"
mkfs.vfat -F 32 -n CBBOOT "$work/boot.vfat" >/dev/null

mkdir -p "$mnt"
mount -o loop "$work/root.ext4" "$mnt"
mkdir -p "$mnt/boot"
mount -o loop "$work/boot.vfat" "$mnt/boot"

echo "==> Install"
# Arch Linux ARM's repos from this system's mirrorlist, plus the local
# couchbox repo. The target gets no copy of this system's keyring (-G) or
# mirrorlist (-M): couchbox-pacman-init makes a keyring per box on first boot.
cat > "$work/pacman.conf" <<EOF
[options]
Architecture = aarch64
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional
ParallelDownloads = 10

[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
[alarm]
Include = /etc/pacman.d/mirrorlist

[couchbox-aarch64]
SigLevel = Optional TrustAll
Server = file://$repo
EOF
pacstrap -C "$work/pacman.conf" -G -M "$mnt" base sudo "${packages[@]}"

echo "==> Boot config"
disk_id=$(od -An -N4 -tx4 /dev/urandom | tr -d ' ')
boot_uuid=PARTUUID=$disk_id-01 root_uuid=PARTUUID=$disk_id-02
cat > "$mnt/etc/fstab" <<EOF
# <device>  <dir>  <type>  <options>  <dump>  <fsck>
$root_uuid  /      ext4    rw,relatime  0  1
$boot_uuid  /boot  vfat    rw,relatime,fmask=0022,dmask=0022  0  2
EOF
# By PARTUUID, so it boots from SD or USB alike (ALARM's stock
# root=/dev/mmcblk0p2 is wrong on some boards). systemd.firstboot=off: the
# image is already configured; don't stop at a console prompt.
sed -i -e "s|root=[^ ]*|root=$root_uuid|" -e 's|$| systemd.firstboot=off|' "$mnt/boot/cmdline.txt"
cat "$mnt/boot/cmdline.txt"

echo "==> System setup"
arch-chroot "$mnt" /bin/bash -euo pipefail <<'EOF'
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=us > /etc/vconsole.conf
echo couchbox > /etc/hostname

# input: CEC and remotes. uucp: USB CEC adapters. video: the V4L2 decoders,
# DMA heaps and the firmware mailbox (vcgencmd).
useradd -m -G wheel,input,uucp,video -s /bin/bash htpc
passwd -l htpc
passwd -l root
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel

# The initramfs pacstrap made used autodetect on the build machine's
# hardware. Make a generic one; later kernel updates on the Pi autodetect
# the Pi itself. (-P ignores -S, so name the image directly.)
for kernel in /usr/lib/modules/*/pkgbase; do
  mkinitcpio -k "$(basename "$(dirname "$kernel")")" -g /boot/initramfs-linux.img -S autodetect
done

# couchbox's services, as couchbox-install enables them: the units its
# preset lists, and nothing else the packages' own presets would.
if [[ -f /usr/lib/systemd/system-preset/80-couchbox.preset ]]; then
  # shellcheck disable=SC2046  # one unit name per word
  systemctl preset $(awk '$1 == "enable" {print $2}' /usr/lib/systemd/system-preset/80-couchbox.preset)
fi
if command -v couchbox-update-app-blacklist >/dev/null; then
  couchbox-update-app-blacklist
fi
EOF

if [[ -n $hook ]]; then
  echo "==> Hook $hook"
  "$hook" "$mnt"
fi

echo "==> Clean up per-box state"
# An empty machine-id makes systemd generate one on first boot, so boxes on
# one network don't share a DHCP client ID.
: > "$mnt/etc/machine-id"
rm -rf "$mnt/etc/pacman.d/gnupg" "$mnt/var/cache/pacman/pkg/"* "$mnt/var/log/journal/"*

umount -R "$mnt"

echo "==> Shrink root"
e2fsck -fy "$work/root.ext4" >/dev/null || [[ $? -le 1 ]]
resize2fs -M "$work/root.ext4" >/dev/null
block_size=$(dumpe2fs -h "$work/root.ext4" 2>/dev/null | awk -F: '/^Block size/ {gsub(/ /, "", $2); print $2}')
blocks=$(dumpe2fs -h "$work/root.ext4" 2>/dev/null | awk -F: '/^Block count/ {gsub(/ /, "", $2); print $2}')
root_mib=$(( (blocks * block_size / 1048576) + root_slack_mib ))
resize2fs "$work/root.ext4" "${root_mib}M" >/dev/null
truncate -s "${root_mib}M" "$work/root.ext4"

echo "==> Image"
boot_sectors=$((boot_mib * 2048)) root_sectors=$((root_mib * 2048))
boot_start=$align_sectors
root_start=$((boot_start + boot_sectors))
total_sectors=$((root_start + root_sectors + align_sectors))
rm -f "$out"
truncate -s $((total_sectors * 512)) "$out"
sfdisk -q "$out" <<EOF
label: dos
label-id: 0x$disk_id
unit: sectors

start=$boot_start, size=$boot_sectors, type=c, bootable
start=$root_start, size=$root_sectors, type=83
EOF
dd if="$work/boot.vfat" of="$out" bs=1M seek=$((boot_start / 2048)) conv=notrunc,sparse status=none
dd if="$work/root.ext4" of="$out" bs=1M seek=$((root_start / 2048)) conv=notrunc,sparse status=none
sfdisk -l "$out"
echo "==> Built $out ($((total_sectors / 2048)) MiB)"
