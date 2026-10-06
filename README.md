# couchbox

couchbox turns a small PC into a TV box. It starts straight into a home
screen made for the couch, where each app is a big tile you pick with a
remote. It's built on Arch Linux and KDE Plasma Bigscreen.

## What you get

- **Apps for watching:**
  - **Ember**, a Jellyfin app that looks and works like Kodi's Amber skin.
  - **Plezy**, for Plex, Jellyfin and Emby.
  - **Kodi**, with its Jellyfin add-ons.
  - **YouTube**, in the same TV version smart TVs use.
  - **IPTV**, free internet TV channels in a channel guide.
- **Remote control.** Bluetooth remotes, such as the Fire TV remote, work
  out of the box. So do Windows Media Center remotes, with the PC's built-in
  IR receiver or Microsoft's USB one.
- **Your media from anywhere.** A built-in ZeroTier client reaches your home
  media server from any network, so the box works the same at a friend's
  house or in a hotel.
- **The TV sleeps by itself.** After 10 minutes with nothing happening, the
  box turns its picture off and most TVs go to sleep. Playing a video keeps
  the picture on.
- **Picks your time zone.** The box sets its time zone from where it is, and
  follows along if you take it somewhere else.
- **Updates.** New versions of couchbox and its apps are published as
  signed updates, so the box can check they're genuine. Install them from
  Konsole on the home screen with `sudo pacman -Syu`.

## Using the remote

- **OK** picks a tile. **Back** goes back.
- **Home**, pressed briefly, goes to the home screen of the app you're in.
  Held, it goes back to couchbox's home screen.
- **Menu**, pressed briefly, opens the app's own menu. Held, it shows the
  apps that are running. Hold OK on one to close it.
- **Power** turns the TV on and brings the picture back.

## Settings

Open **Settings** on the home screen. Besides the usual Wi-Fi, Bluetooth,
sound and display pages, the **couchbox** page has:

- **YouTube:** which video formats to play, the start page, and hiding
  Shorts.
- **Video playback:** lighter settings for older or low-power PCs. couchbox
  picks these for your hardware the first time it starts; "Detect hardware
  again" goes back to them. See
  [docs/video-settings.md](docs/video-settings.md).
- **Time:** turn off the automatic time zone.
- **Apps in the background:** keep music playing when you leave its app.

## What it runs on

couchbox needs a 64-bit Intel or AMD PC that boots in UEFI mode. It runs on
an Intel NUC (NUC6i5SYB) and on a Gigabyte BRIX with a low-power Celeron
N2807. It hasn't been tried on AMD hardware yet.

## Installing

Each [release](https://github.com/jpsutton/couchbox/releases) has two
installers to put on a USB stick:

- **The full installer** (about 2 GiB) installs without a network.
- **The netinstall** (about 340 MiB) downloads everything during the
  install, over a cable or Wi-Fi.

Boot the PC from the stick, pick the disk, and set a password if you want
one. **The installer erases the whole disk.** When it's done, remove the
stick and restart into couchbox.

To turn an Arch Linux install you already have into couchbox, or for help
when the PC won't start after installing, see
[docs/install.md](docs/install.md).

## More detail

- [docs/install.md](docs/install.md): the installers, start-up problems, and
  installing on an existing Arch system.
- [docs/components.md](docs/components.md): every piece of couchbox and the
  package it comes from.
- [docs/home-screen.md](docs/home-screen.md): which apps get a tile, and how
  to add one.
- [docs/display-sleep.md](docs/display-sleep.md): how the TV goes to sleep,
  and how to change the timeout.
- [docs/video-settings.md](docs/video-settings.md): the playback settings
  for low-power PCs.
- [docs/time-zone.md](docs/time-zone.md): the automatic time zone.
- [docs/development.md](docs/development.md): building couchbox, branches,
  CI and releases.
- [docs/roadmap.md](docs/roadmap.md): ideas and open work.
- [UPSTREAM-BUGS.md](UPSTREAM-BUGS.md): bugs found in other projects, and
  how couchbox works around them.
