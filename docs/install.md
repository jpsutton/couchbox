# Installing couchbox

1. Boot the ISO in UEFI mode. BIOS boot is not supported.
2. The installer starts by itself on the console. Pick the disk from the
   menu, confirm, and set a password for `htpc` (or leave it empty).

For unattended installs, run `couchbox-install --yes /dev/<disk>` instead.

The full ISO (`couchbox-*.iso`, about 2 GiB) needs no network. It carries an
offline repo with every package the installer uses, for both Intel and AMD
boxes; the list lives in `iso/target-packages`.

The netinstall ISO (`couchbox-net-*.iso`) carries only the live system and
downloads the same package list during the install (about 1.5 GiB): Arch
packages from Arch's geo mirror, couchbox packages from the latest GitHub
release, checked against the couchbox key. Wired networks come up by
themselves (DHCP). With no connection, the installer offers a Wi-Fi menu
(iwd; open and WPA-Personal networks; for others, quit to the shell and use
`iwctl`). A Wi-Fi network picked there is also saved for NetworkManager on
the installed system, so the box comes up online. To stay small (about 340
MiB), the live system has firmware for Wi-Fi chips and Realtek Ethernet only,
no GPU, sound, camera or server-hardware drivers (the console stays on the
UEFI framebuffer), and boots with GRUB, which reads the kernel from the ISO
instead of a second copy in the EFI partition.

Either way, the installed system is set up for online updates: Arch's geo
mirror plus the signed couchbox repo on GitHub releases (see [Releases](development.md#releases)).

The installer **erases the whole disk**. It never offers the USB stick it
booted from, and the erase prompt defaults to No. It creates a GPT with a 1
GiB ESP and an ext4 root, installs systemd-boot, and creates the `htpc` user.
SDDM logs that user in automatically. The `htpc` password is only for sudo and
SSH; root stays locked. Use `--yes` to skip the prompts, which leaves the
`htpc` password locked.

If the box shows "Reboot and select proper boot device" after the install,
the firmware is trying a legacy (CSM) boot of the disk. Pick the disk's UEFI
entry ("UEFI OS", "Linux Boot Manager" or "UEFI: <disk>") in the firmware's
boot menu, or turn CSM off. Some AMI firmware (seen on a Bay Trail BRIX and a
Foxconn AT-5570) also drops the boot entry the installer creates. The BRIX
then boots through the fallback loader, `\EFI\BOOT\BOOTX64.EFI`, which the
installer also writes; the Foxconn lands in its built-in EFI shell instead,
which runs the `startup.nsh` the installer puts on the ESP to start
systemd-boot. `bootctl install` recreates the entry.

The boot shows the kernel's messages and systemd's service status until the
Bigscreen session starts: no `quiet`, so a slow disk never means minutes of
black screen.

## On an existing Arch install

Every couchbox package, including the AUR ones it uses (the Kodi add-ons),
is in the couchbox repo, so an Arch system with a bootloader and a network
connection can become a couchbox box without the ISO. couchbox-base takes
over the machine: it logs `htpc` straight into Bigscreen with no lock
screen, ships system-wide Plasma defaults in `/etc/xdg`, and uses
NetworkManager and SDDM. Use a machine meant to be the HTPC, not a desktop.

1. Trust the couchbox signing key:

   ```
   curl -sL https://raw.githubusercontent.com/jpsutton/couchbox/release/packages/couchbox-keyring/couchbox.gpg | sudo pacman-key --add -
   sudo pacman-key --lsign-key 30DF04A7B6501BD317ADD964250A71E231E76DE0
   ```

2. Add the repo to `/etc/pacman.conf`, after Arch's repos (see
   [Releases](development.md#releases)):

   ```
   [couchbox]
   SigLevel = Required
   Server = https://github.com/jpsutton/couchbox/releases/latest/download
   ```

3. Install couchbox, plus the graphics drivers and microcode for the CPU
   (the installer's lists are in `iso/target-packages`):

   ```
   sudo pacman -Syu couchbox-base
   sudo pacman -S --needed intel-ucode intel-media-driver libva-intel-driver vulkan-intel  # Intel
   sudo pacman -S --needed amd-ucode vulkan-radeon                                         # AMD
   ```

   Regenerate the boot entries if the bootloader needs to load the new
   microcode.

4. Create the `htpc` user after couchbox-base is installed, so it gets the
   files from `/etc/skel` (app tiles, Plezy and Kodi defaults). An existing
   `htpc` account doesn't get them; copy them from `/etc/skel` by hand.

   ```
   sudo useradd -m -G wheel,input,uucp htpc
   sudo passwd htpc  # optional: for sudo and SSH; autologin needs none
   ```

5. Turn off any other display manager or network service (for example
   `gdm`, `systemd-networkd`, `iwd`), then enable couchbox's services, the
   same preset the installer applies:

   ```
   sudo systemctl preset $(awk '$1 == "enable" { print $2 }' /usr/lib/systemd/system-preset/80-couchbox.preset)
   ```

6. Reboot. SDDM logs `htpc` into Bigscreen.

Updates come with `pacman -Syu`, the same as on an ISO install.
