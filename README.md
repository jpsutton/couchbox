# couchbox

An Arch-based HTPC appliance for streaming from Jellyfin. It boots straight
into KDE Plasma Bigscreen with each Jellyfin client pinned as a home-screen
tile, so you can switch between clients from the couch. Bluetooth remotes
control it. A built-in ZeroTier client reaches the home server from any
network.

The build produces an installer ISO. You boot it, run one command, and get a
finished box.

**Status:** the ISO builds, and a QEMU/OVMF test passed on 2026-09-28. The
unattended install (`couchbox-install --yes`) finished, and the installed
system booted straight into Bigscreen with the Jellyfin and Kodi tiles
pinned. Both tiles launched their client. Nothing has run on real hardware
yet.

## What's in the image

| Piece | Source |
|---|---|
| Plasma Bigscreen session (6.7+) | `extra` |
| SDDM autologin into Bigscreen, no lock screen | `couchbox-base` |
| Jellyfin Desktop, TV mode (`jellyfin-desktop --fullscreen --tv`) | AUR |
| Kodi with `jellyfin-kodi` and `JellyCon` | `extra` and AUR |
| ZeroTier (`zerotier-one`, enabled at boot) | `extra` |
| BlueZ, CEC (`libcec`), PipeWire, NetworkManager | `extra` |
| VA-API driver and microcode, picked by CPU vendor | installer |
| HDMI off after 10 idle minutes, never system suspend | `couchbox-base` (PowerDevil) |

## Idle display-off

After 10 minutes with no input, PowerDevil turns the HDMI output off (DPMS).
The TV sees "no signal" and goes to sleep on its own. A remote key turns the
output back on. Most TVs stay asleep after that, so turn the TV back on with
its power key (fire-blaster sends it as IR). The box itself never suspends,
because a sleeping PC drops the Bluetooth remote and ZeroTier.

Two settings make this work, both installed to `/etc/xdg`:

- `plasmabigscreenrc` sets `pmInhibitionEnabled=false`. Bigscreen holds a
  system-wide power inhibit by default, and that inhibit blocks display-off
  completely. You can switch it back on under Bigscreen Settings, in the
  "Power inhibition" option.
- `powerdevilrc` sets the timeout, disables dimming and sets
  `AutoSuspendAction=0`. To change the timeout, edit
  `TurnOffDisplayIdleTimeoutSec`.

Playback keeps the screen on. Jellyfin Desktop holds an inhibit through
`org.freedesktop.ScreenSaver`, and Kodi holds one through Wayland
idle-inhibit.

## Layout

```
aur.txt                   AUR packages to build, in order, with their local deps
packages/couchbox-base/   meta package and appliance config
scripts/build-repo.sh     builds the AUR and local packages in a clean chroot into out/repo
scripts/build-iso.sh      copies archiso's releng profile, overlays iso/, embeds out/repo
iso/airootfs/             files added to the live ISO, including couchbox-install
```

## Build

On an Arch host with `devtools`, `archiso` and `pacman-contrib` installed:

```sh
make check   # static checks, no root needed
make repo    # clean-chroot builds into out/repo (asks for sudo)
make iso     # out/couchbox-*.iso
```

## Install

1. Boot the ISO in UEFI mode.
2. Connect to the network. The mirrors supply everything except the AUR builds.
3. Run `couchbox-install /dev/nvme0n1`.

The installer **erases the whole disk**. It asks you to type the disk name
before it starts. It creates a GPT with a 1 GiB ESP and an ext4 root, installs
systemd-boot, and creates the `htpc` user. SDDM logs that user in
automatically. The `htpc` password is only for sudo and SSH. Use `--yes` to
skip the prompts, which leaves the `htpc` password locked.

## How the tiles work

Bigscreen keeps its home-screen favorites in `~/.config/bigscreen-favs`. It
matches each favorite on the `.desktop` file ID *and* the exact `Exec` line.
`couchbox-base` generates that file from its own tile `.desktop` files and
installs it to `/etc/skel`. New users start with the tiles pinned. To add a
client, add a `couchbox-*.desktop` file and list it in `_tiles` in the
PKGBUILD.

## Roadmap

- **ZeroTier tile.** A Kirigami app shows join status and a QR code. Scanning
  the code opens a small web page on the box, served on the LAN, where you
  paste the 16-character network ID from your phone. Both parts talk to the
  `zerotier-one` local API on port 9993.
- **First-time remote pairing.** A new box has no paired remote, so you can't
  open Bluetooth settings. Add a helper that makes the adapter pairable at
  boot until the first HID device pairs.
- **Kodi add-ons disabled at first launch.** Kodi turns off add-ons that were
  installed outside its add-on manager. On first launch it asks once per
  add-on whether to enable it (confirmed in QEMU). To skip those prompts,
  enable `plugin.video.jellyfin` and `plugin.video.jellycon` on first run
  through JSON-RPC.
- **Verify idle display-off on hardware.** Check that idle Kodi menus don't
  keep the inhibit, which would stop the TV from sleeping. Check that paused
  Jellyfin playback releases it. Optionally, send CEC standby to the TV on
  idle, for TVs that ignore "no signal". That needs a CEC adapter and has to
  share it with the Bigscreen input handler.
- **fire-blaster.** Package `../fire-blaster` and add it to `packages/`.
- **Hotel captive portals.** Test the NetworkManager captive-portal flow
  inside Bigscreen, which has no normal browser window.
- **Updates.** Host `out/repo` somewhere so installed boxes get AUR rebuilds
  without a reinstall. Sign the packages when that happens.
- **aarch64.** archiso can build UEFI AArch64 ISOs. That covers boards with
  EDK2 firmware, such as RK3588 boards, but not a stock Raspberry Pi 5.
  Needs `iso/packages.aarch64` and a kernel choice in the installer.
- **More clients.** `jellyfin-mpv-shim` (in `extra`) as a user service, so a
  phone can cast to the box. Also the independent fork of the Jellyfin
  desktop rewrite, once it's packaged.
