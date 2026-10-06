# Roadmap

Ideas and open work.

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
- **Applications grid on the home screen.** Bigscreen shows each category as
  one horizontal row, and 6.7.5 has no setting for a grid. A wrapping grid was
  tried on the BRIX (6 columns at 1920 wide) and reverted. 2D navigation
  and the separate Games grid worked well. What we learned:
  - The homescreen QML is a plain package in
    `/usr/share/plasma/plasmoids/org.kde.bigscreen.homescreen`, not compiled
    into the plugin. A copy under `~/.local/share/plasma/plasmoids/` with the
    same id takes precedence, so the layout can change without rebuilding
    `plasma-bigscreen`.
  - The change is small: a new `launcher/DelegateGridView.qml` (about 110
    lines of code, a `GridView` reworking of `DelegateListView.qml`), plus
    about 20 changed lines in `launcher/LauncherHome.qml` (use the grid for
    Applications and Games, and scroll the page to the focused row) and
    `launcher/delegates/IconDelegate.qml` (tile height from the cell height).
  - Proposed packaging: a pacman hook in `couchbox-base` on changes to the
    homescreen package. It copies the pristine package, applies the edits
    with `patch --fuzz=2`, and swaps the result into
    `/usr/local/share/plasma/plasmoids/` (to be checked: that path must come
    before `/usr/share` in `XDG_DATA_DIRS`). A stamp file records the
    `plasma-bigscreen` version and checksums.
  - If patching fails after an upgrade, keep the previous override only when
    the plugin `.so` and the `org.kde.bigscreen` QML module are unchanged.
    Otherwise fall back to the stock rows, because old QML against a changed
    plugin can break the home screen. Either way, log the failure and show a
    notification so it isn't silent.
  - To test with more tiles, add dummy `.desktop` files under
    `~/.local/share/applications` (`Exec=true`; `Categories=Game;` for the
    Games section) and run `kbuildsycoca6`. The couchbox blacklist only
    covers `/usr/share/applications`, and the app list reloads on its own.
  - The stock shell already logs `Maximum call stack size exceeded` from
    `LauncherMenu.qml` at startup; it is not caused by the grid.
- **More apps.** Candidates: `jellyfin-mpv-shim` (in `extra`) as a user
  service, so a phone can cast to the box, and the independent fork of the
  Jellyfin desktop rewrite, once it's packaged.
