# What's in couchbox

Each piece of the installed system, and the package or step that provides it.

| Piece | Source |
|---|---|
| Plasma Bigscreen session (6.7+) | `extra` |
| SDDM autologin into Bigscreen, no lock screen | `couchbox-base` |
| Kodi, with the Jellyfin add-ons `jellyfin-kodi` and `JellyCon` | `extra` and AUR |
| Plezy (native Flutter client for Plex, Jellyfin and Emby; TV mode and fullscreen preset), patched for the remote and TV | `plezy-couchbox` |
| YouTube, TV interface (`youtube.com/tv` with a TV user agent; account picker, Link with TV code) | `couchbox-youtube` |
| IPTV: free internet TV ([iptv-org](https://github.com/iptv-org/iptv)'s channels) in a channel guide, with a nightly refresh of channels, streams and guide | `couchbox-iptv`, built from [couchbox-iptv](https://github.com/jpsutton/couchbox-iptv) |
| Ember: Jellyfin client that browses like Kodi's Amber skin (vertical menu, list views with a details pane), Quick Connect sign-in | `ember`, built from [ember](https://github.com/jpsutton/ember) |
| ZeroTier (`zerotier-one`, enabled at boot) | `extra` |
| BlueZ, CEC (`libcec`), PipeWire, NetworkManager | `extra` |
| HDMI/DisplayPort audio as the default output when present (a default you pick still wins) | `couchbox-base` (WirePlumber rule) |
| VA-API driver and microcode, picked by CPU vendor | installer |
| Time zone from the network's location, at install and every login (see [time-zone.md](time-zone.md)) | installer, `couchbox-base` (`couchbox-timezone`) |
| HDMI off after 10 idle minutes, never system suspend | `couchbox-base` (PowerDevil) |
| Home screen shows only the app tiles, Konsole and Settings | `couchbox-base` (`/etc/couchbox/visible-apps`) |
| Bluetooth pairing agent that accepts and trusts remotes | `couchbox-base` (`couchbox-bt-agent`) |
| Short Home/Menu go to the app; long Home shows the Bigscreen launcher, long Menu the home overlay (Tasks page: hold OK to close an app); OK and Menu remapped for apps | `fire-blaster` (`[hold]`, `[remap]`), `couchbox-base` (KWin script, shortcut defaults) |
| fire-blaster (remote grab, long-press keys; IR once a blaster is fitted) | `packages/fire-blaster`, built from `../fire-blaster` |
