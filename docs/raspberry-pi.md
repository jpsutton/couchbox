# couchbox on the Raspberry Pi

couchbox runs on the Raspberry Pi 4 Model B, Pi 400 and Compute Module 4.
It's built on Arch Linux ARM instead of Arch Linux. The Pi 5 and the Pi 3 are
best effort: the image doesn't shut them out, but they aren't tested.

## What you need

- A Pi 4 with 2 GB of RAM or more. 4 GB is what couchbox is tested on.
- **Active cooling.** A fan, or a large heatsink case. With a small passive
  heatsink, playback pushes the SoC past 60 °C, its soft limit, and the CPU
  slows down. A 5 V fan keeps it under 50 °C.
- An SD card of 8 GB or more.
- A micro-HDMI cable, plugged into **HDMI0**, the port next to the USB-C power
  jack. Use a real cable, not a micro-HDMI adapter on a regular cable: some
  adapters don't carry the pins the Pi uses to detect the display and read
  its modes, so the Pi shows nothing once it has started.

## Flashing

Write the image to the card with `ddrescue`. Its progress shows what has
reached the card, not what is still in the write cache. Check the card's
device name with `lsblk` first: this overwrites the whole device.

```bash
xz -d couchbox-rpi-*.img.xz
```

```bash
sudo ddrescue -d -D --force couchbox-rpi-*.img /dev/sdX
```

## First-boot setup

There is no installer. Before the first start, you can put a
`couchbox-setup.txt` on the card's boot partition, the FAT one any computer
can open. `couchbox-setup.txt.example` there lists the settings:

- the `htpc` password, for system updates and SSH;
- Wi-Fi network, password and country;
- hostname and time zone;
- SSH on or off, and an SSH key;
- a ZeroTier network to join.

couchbox applies the file once on the first boot and then deletes it, because
it holds passwords. Without it, the TV still logs in on its own, but the
`htpc` account stays locked, so `sudo pacman -Syu` can't run until a password
is set.

The first boot also grows the root filesystem to fill the card and makes a
pacman keyring for this box.

## Video decoding

| Board | Hardware decode | Software |
|---|---|---|
| Pi 4, 400, CM4 | H.264 up to 1080p60, HEVC (8- and 10-bit) up to 4K | MPEG-2 (no decoder), VP9 and AV1 (the server converts them) |
| Pi 5 | HEVC | H.264 in software (fast enough at 1080p) |
| Pi 3 | H.264; MPEG-2 and VC-1 with a purchased licence key | HEVC |

How it fits together:

- **The kernel is `linux-rpi`**, the Raspberry Pi kernel. Mainline Linux has
  none of the Pi's decoder drivers.
- **FFmpeg is `ffmpeg-rpi`.** Upstream FFmpeg can't use the HEVC decoder, so
  couchbox's `mpv-rpi` is mpv built against it. Ember and couchbox-iptv use
  its `libmpv`.
- **couchbox-video-profile** finds the V4L2 decoders and sets
  `Hwdec=drm,v4l2m2m` and `VideoSync=audio` (see
  [video-settings.md](video-settings.md)). Both decode modes hand frames to
  the GPU without a copy.
- **YouTube runs in Chromium,** with the same page code as the Electron app on
  PCs. Electron's ARM builds can't use the Pi's decoders.

Measured on a Pi 4 (decode only, 20-second test clips):

| Clip | Hardware | Software |
|---|---|---|
| H.264 1080p60 | 77 fps, 24% CPU | 112 fps, 350% CPU |
| HEVC 1080p30 | 132 fps | 44 fps |
| HEVC 4K30 10-bit, copied to the CPU (`drm-copy`) | 24 fps | 7 fps |
| MPEG-2 1080i, decode plus `bwdif` deinterlace | — | 112 fields/s, ~1.4 cores in real time |

The GPU, not the decoders, limits playback.

- **4K needs zero-copy.** `drm-copy` caps 4K HEVC at 24–35 fps, because one
  CPU core converts the decoder's tiled output. Zero-copy (`drm`) skips that.
- **1080p30 in Ember with zero-copy decode** still drops about 4 frames a
  second, with the V3D GPU 86% busy drawing them. Timing to the display's
  refresh (`display-resample`) dropped about 17.

Handing the decoder's frames straight to the display hardware, the way Kodi
and Raspberry Pi OS do, would take the GPU out of video entirely. That is open
work; see [roadmap.md](roadmap.md).

## Display notes

- **KWin uses only the display device.** The Pi's 3D GPU (v3d) and its display
  controller (vc4) are separate DRM devices. couchbox-rpi points KWin at vc4
  (`KWIN_DRM_DEVICES`); with both, KWin drew on v3d, the kernel logged
  "swiotlb buffer is full", and the screen stayed blank.
- **A display the Pi can't detect** (no EDID or hotplug, as with a bad
  adapter) shows nothing once Linux takes over from the boot firmware. To
  force HDMI0 on at 1080p60, add this to the end of the line in
  `/boot/cmdline.txt`:

  ```
  video=HDMI-A-1:1920x1080@60D
  ```
