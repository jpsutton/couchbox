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
| Kodi with `jellyfin-kodi` and `JellyCon` | `extra` and AUR |
| Plezy (native Flutter Plex/Jellyfin client; TV mode and fullscreen preset), patched for the remote and TV | `plezy-couchbox` |
| YouTube, TV interface (`youtube.com/tv` with a TV user agent; account picker, Link with TV code) | `couchbox-youtube` |
| ZeroTier (`zerotier-one`, enabled at boot) | `extra` |
| BlueZ, CEC (`libcec`), PipeWire, NetworkManager | `extra` |
| VA-API driver and microcode, picked by CPU vendor | installer |
| HDMI off after 10 idle minutes, never system suspend | `couchbox-base` (PowerDevil) |
| Home screen shows only the tiles, Konsole and Settings | `couchbox-base` (`/etc/couchbox/visible-apps`) |
| Bluetooth pairing agent that accepts and trusts remotes | `couchbox-base` (`couchbox-bt-agent`) |
| Short Home/Menu go to the app; long Home shows the Bigscreen launcher, long Menu the home overlay (Tasks page: hold OK to close an app); OK and Menu remapped for apps | `fire-blaster` (`[hold]`, `[remap]`), `couchbox-base` (KWin script, shortcut defaults) |
| fire-blaster (remote grab, long-press keys; IR once a blaster is fitted) | `packages/fire-blaster`, built from `../fire-blaster` |

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

Playback keeps the screen on. Plezy holds an inhibit through the desktop
portal (`org.freedesktop.portal.Inhibit`), and Kodi holds one through Wayland
idle-inhibit.

## Layout

```
aur.txt                   AUR packages to build, in order, with their local deps
packages/couchbox-base/   meta package and appliance config
packages/kodi-addon-couchbox-shuffle/  Kodi context menu on shows and seasons: Shuffle one, Shuffle all
packages/plezy-couchbox/  Plezy with couchbox's patches (Home key, Play/Pause, Display Scale); provides plezy
packages/couchbox-youtube/  YouTube's TV interface (youtube.com/tv) in a fullscreen window on the system electron
packages/couchbox-wallpapers/  14 TV-friendly KDE wallpapers; Bigscreen's default slideshow rotates through them
packages/couchbox-settings/  "couchbox" page in Bigscreen Settings (KCM); options in ~/.config/couchboxrc
scripts/build-repo.sh     builds the AUR and local packages in a clean chroot into out/repo
                          (packs ../fire-blaster, or $FIRE_BLASTER_SRC, as fire-blaster's source)
scripts/build-iso.sh      releng profile with a minimal live system, plus an offline repo of everything the target needs
iso/target-packages       what the installer puts on a target, by CPU vendor
iso/airootfs/             files added to the live ISO, including couchbox-install
disabled-packages/        kept but not built: jellium-desktop (patched Jellium, off since 2026-09-29),
                          jellyfin-desktop (its tile, TV-mode launcher and remote input map, removed 2026-10-01)
```

## Build

On an Arch host with `devtools`, `archiso` and `pacman-contrib` installed:

```sh
make check   # static checks, no root needed
make repo    # clean-chroot builds into out/repo (asks for sudo)
make iso     # out/couchbox-*.iso
```

## Install

1. Boot the ISO in UEFI mode. BIOS boot is not supported.
2. The installer starts by itself on the console. Pick the disk from the
   menu, confirm, and set a password for `htpc` (or leave it empty).

For unattended installs, run `couchbox-install --yes /dev/<disk>` instead.

No network is needed. The ISO carries an offline repo with every package the
installer uses, for both Intel and AMD boxes; the list lives in
`iso/target-packages`. The installed system is set up for online updates:
Arch's geo mirror plus the couchbox repo copied to `/var/lib/couchbox/repo`.

The installer **erases the whole disk**. It never offers the USB stick it
booted from, and the erase prompt defaults to No. It creates a GPT with a 1
GiB ESP and an ext4 root, installs systemd-boot, and creates the `htpc` user.
SDDM logs that user in automatically. The `htpc` password is only for sudo and
SSH; root stays locked. Use `--yes` to skip the prompts, which leaves the
`htpc` password locked.

## How the tiles work

The home screen shows one row, Applications, which Bigscreen sorts by name. It
lists only the apps in `/etc/couchbox/visible-apps`: the Jellyfin, Kodi and
Plezy clients, Konsole and Bigscreen Settings. couchbox ships no Bigscreen
favorites, so the Favorites row, which appears only when it has entries, stays
hidden. The Recent row appears only when app-usage history exists, so
`/etc/xdg/kactivitymanagerd-pluginsrc` turns that history off
(`what-to-remember=2`).

Each client's tile overrides the app's own `.desktop` file under the same file
ID, in `~/.local/share/applications` (copied from `/etc/skel`). The ID has to
match the window's app ID: Bigscreen raises a running app only when they
match, and otherwise launches it again. The override is also where a tile
can swap in its own launcher or arguments (Kodi's audio backend). To add a client, add
a `<app id>.desktop` file, list it in `_tiles` in the PKGBUILD, and add the
ID to `visible-apps`.

## Upstream bugs

[UPSTREAM-BUGS.md](UPSTREAM-BUGS.md) tracks bugs found in upstream projects,
mostly Plasma Bigscreen, along with the couchbox workaround for each.

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
- **fire-blaster IR.** fire-blaster is packaged and handles the long Home
  press, but its IR output is a stub, so couchbox leaves `[keys]` empty and
  volume/mute/power go to Plasma. Once a USB IR blaster is fitted, fill
  `[keys]` in `/etc/fire-blaster/config.toml` and add `pyside6` for the
  on-screen setup overlay.
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
