# couchbox

A general-purpose HTPC operating system, based on Arch Linux. It boots
straight into KDE Plasma Bigscreen, where each app is a tile on the home
screen: Kodi, Plezy (a Plex, Jellyfin and Emby client) and YouTube's TV
interface so far, with more to come. You switch between apps from the couch,
and Bluetooth remotes control the box. A built-in ZeroTier client reaches a
home media server from any network.

The build produces two installer ISOs: a full one that installs offline, and
a small netinstall one that downloads everything during the install. You boot
either one, pick a disk, and get a finished box.

**Status:** runs on an Intel NUC (Skylake, NUC6i5SYB), and installed from the
netinstall ISO on a Gigabyte BRIX (Bay Trail Celeron N2807). Installs from
both ISOs also pass in QEMU/OVMF. Not yet tried on AMD hardware.

## What's in the image

| Piece | Source |
|---|---|
| Plasma Bigscreen session (6.7+) | `extra` |
| SDDM autologin into Bigscreen, no lock screen | `couchbox-base` |
| Kodi, with the Jellyfin add-ons `jellyfin-kodi` and `JellyCon` | `extra` and AUR |
| Plezy (native Flutter client for Plex, Jellyfin and Emby; TV mode and fullscreen preset), patched for the remote and TV | `plezy-couchbox` |
| YouTube, TV interface (`youtube.com/tv` with a TV user agent; account picker, Link with TV code) | `couchbox-youtube` |
| ZeroTier (`zerotier-one`, enabled at boot) | `extra` |
| BlueZ, CEC (`libcec`), PipeWire, NetworkManager | `extra` |
| HDMI/DisplayPort audio as the default output when present (a default you pick still wins) | `couchbox-base` (WirePlumber rule) |
| VA-API driver and microcode, picked by CPU vendor | installer |
| HDMI off after 10 idle minutes, never system suspend | `couchbox-base` (PowerDevil) |
| Home screen shows only the app tiles, Konsole and Settings | `couchbox-base` (`/etc/couchbox/visible-apps`) |
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
                          (YouTube codecs, video settings for the hardware)
scripts/build-repo.sh     builds the AUR and local packages in a clean chroot into out/repo
                          (packs ../fire-blaster, or $FIRE_BLASTER_SRC, as fire-blaster's source)
scripts/build-iso.sh      releng profile with a minimal live system; full: plus an offline repo of everything
                          the target needs; net: plus Wi-Fi and network firmware instead
iso/target-packages       what the installer puts on a target, by CPU vendor
iso/airootfs/             files added to both live ISOs, including couchbox-install
iso/airootfs-net/, iso/packages-net.x86_64, iso/net-noextract.conf, iso/net-drop-modules
                          netinstall ISO only: motd and initramfs config, extra packages, and the
                          firmware and kernel modules it leaves out (scripts/*-noextract.sh)
disabled-packages/        kept but not built: jellium-desktop (patched Jellium, off since 2026-09-29),
                          jellyfin-desktop (its tile, TV-mode launcher and remote input map, removed 2026-10-01)
```

## Build

On an Arch host with `devtools`, `archiso`, `pacman-contrib` and `grub` (netinstall ISO only) installed:

```sh
make check   # static checks, no root needed
make repo    # clean-chroot builds into out/repo (asks for sudo)
make iso     # out/couchbox-*.iso
make netiso  # out/couchbox-net-*.iso; needs no `make repo`
```

## Branches and CI

Changes go feature branch -> `staging` -> `release`, each step a pull request.
`staging` is the default branch.

| Event | Workflow | What runs |
|---|---|---|
| PR into `staging` or `release` | `checks` | `scripts/check.sh` (same as `make check`), about a minute |
| PR into `release` | `checks` | also: the PR must come from `staging` |
| PR into `release` | `build` | every package in an `archlinux:base-devel` container (`scripts/ci/build-packages.sh`), then the ISO in a privileged one (`scripts/ci/build-iso.sh`), and the netinstall ISO in parallel (`scripts/ci/build-iso.sh net`); all uploaded as artifacts |
| merge into `release` | `release` | no rebuild: takes the PR's build artifacts, signs the packages and repo database, tags `YYYY.MM.DD`, and publishes a GitHub Release |

Merge staging -> release PRs with **Create a merge commit**: the release
workflow finds the PR's build through the merge commit's second parent, and
refuses to publish if the merged tree differs from what was built.

## Releases

Each release carries both ISOs (the full one when it fits GitHub's 2 GiB asset
limit) and the couchbox pacman repo: the packages, a detached `.sig` for each, and the signed
`couchbox.db`. Installed boxes use it as

```
[couchbox]
SigLevel = Required
Server = https://github.com/jpsutton/couchbox/releases/latest/download
```

trusting the key in `couchbox-keyring` (fingerprint `30DF04A7B6501BD317ADD964250A71E231E76DE0`).
The private key is the `COUCHBOX_GPG_KEY` repository secret; only the release
workflow reads it. To roll a box back, point `Server` at an older release:
`.../releases/download/<tag>`.

## Install

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
mirror plus the signed couchbox repo on GitHub releases (see Releases below).

The installer **erases the whole disk**. It never offers the USB stick it
booted from, and the erase prompt defaults to No. It creates a GPT with a 1
GiB ESP and an ext4 root, installs systemd-boot, and creates the `htpc` user.
SDDM logs that user in automatically. The `htpc` password is only for sudo and
SSH; root stays locked. Use `--yes` to skip the prompts, which leaves the
`htpc` password locked.

If the box shows "Reboot and select proper boot device" after the install,
the firmware is trying a legacy (CSM) boot of the disk. Pick the disk's UEFI
entry ("UEFI OS", "Linux Boot Manager" or "UEFI: <disk>") in the firmware's
boot menu, or turn CSM off. Some AMI firmware (seen on a Bay Trail BRIX) also
drops the boot entry the installer creates; the box then boots through the
fallback loader, `\EFI\BOOT\BOOTX64.EFI`, which the installer also writes.

## How the tiles work

The home screen shows one row, Applications, which Bigscreen sorts by name. It
lists only the apps in `/etc/couchbox/visible-apps`: Kodi, Plezy, YouTube,
Konsole and Bigscreen Settings. couchbox ships no Bigscreen favorites, so the
Favorites row, which appears only when it has entries, stays hidden. The
Recent row appears only when app-usage history exists, so
`/etc/xdg/kactivitymanagerd-pluginsrc` turns that history off
(`what-to-remember=2`).

A tile that needs its own launcher or arguments overrides the app's `.desktop`
file under the same file ID, in `~/.local/share/applications` (copied from
`/etc/skel`). The ID has to match the window's app ID: Bigscreen raises a
running app only when they match, and otherwise launches it again. Kodi's tile
does this for its audio backend, and Plezy's to set the window class
(`StartupWMClass`) Bigscreen matches; YouTube ships its own `.desktop` file in
`couchbox-youtube`. To add an app, add its desktop file ID to `visible-apps`;
if it needs an override, add a `<app id>.desktop` file to `couchbox-base` and
list it in `_tiles` in the PKGBUILD.

## Video settings for the hardware

Older and low-power graphics need lighter playback settings. On a Bay Trail
Celeron N2807, mpv's default scaling in Plezy dropped a quarter of the frames
of 1080p H.264 that the GPU itself decodes easily, and software HEVC is barely
real time on its two cores.

Each tweak is its own setting under "Video playback" on the couchbox page in
Bigscreen Settings (`[Video]` in `~/.config/couchboxrc`):

| Setting | What it changes |
|---|---|
| Plezy picture scaling: Fast | bilinear scalers, no dithering, in Plezy's mpv.conf setting (a marked block; other lines stay) |
| Ask the server to convert: HEVC, HEVC 10-bit, AV1, VP9 | Plezy's refused codecs (HEVC, AV1; Plezy 2.22+), Jellyfin for Kodi's transcode options, JellyCon's force-transcode options |

`couchbox-video-profile` (in `couchbox-base`) picks the defaults once, at the
first login (a user service). It reads what the GPU decodes from `vainfo`. A
GPU without hardware HEVC decode counts as low-power: Fast scaling, and the
server converts every codec the GPU can't decode. Other GPUs keep the clients'
own defaults. Nothing resets the settings later, so changes made on the page
or inside Plezy or Kodi stay; "Detect hardware again" on the page re-runs the
probe. A change on the page reaches a client that is running once it exits,
because both rewrite their settings files while they run.

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
  playback releases it. Optionally, send CEC standby to the TV on
  idle, for TVs that ignore "no signal". That needs a CEC adapter and has to
  share it with the Bigscreen input handler.
- **fire-blaster IR.** fire-blaster is packaged and handles the long Home
  press, but its IR output is a stub, so couchbox leaves `[keys]` empty and
  volume/mute/power go to Plasma. Once a USB IR blaster is fitted, fill
  `[keys]` in `/etc/fire-blaster/config.toml` and add `pyside6` for the
  on-screen setup overlay.
- **Hotel captive portals.** Test the NetworkManager captive-portal flow
  inside Bigscreen, which has no normal browser window.
- **aarch64.** archiso can build UEFI AArch64 ISOs. That covers boards with
  EDK2 firmware, such as RK3588 boards, but not a stock Raspberry Pi 5.
  Needs `iso/packages.aarch64` and a kernel choice in the installer.
- **More apps.** Candidates: `jellyfin-mpv-shim` (in `extra`) as a user
  service, so a phone can cast to the box, and the independent fork of the
  Jellyfin desktop rewrite, once it's packaged.
