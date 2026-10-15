# What's in couchbox

Each piece of the installed system, and the package or step that provides it.

Kodi (with its Jellyfin add-ons) and Plezy are no longer installed by
default; Ember is the media client. The `[couchbox]` repo still carries
`plezy-couchbox`, `kodi-addon-couchbox-shuffle` and the AUR add-ons, so
`sudo pacman -S kodi kodi-addon-jellyfin python-typing_extensions plezy-couchbox`
brings them back (as the stock apps, without couchbox's tile overrides and
defaults).
Boxes installed before couchbox-base 0.12.3 keep them installed; their tiles
go with the update unless `/etc/couchbox/visible-apps` was edited there (then
pacman leaves a `.pacnew` to merge).

| Piece | Source |
|---|---|
| Plasma Bigscreen session (6.7+) | `extra` |
| SDDM autologin into Bigscreen, no lock screen | `couchbox-base` |
| YouTube, TV interface (`youtube.com/tv` with a TV user agent; account picker, Link with TV code) | `couchbox-youtube` |
| IPTV: free internet TV ([iptv-org](https://github.com/iptv-org/iptv)'s channels) in a channel guide, with a nightly refresh of channels, streams and guide | `couchbox-iptv`, built from [couchbox-iptv](https://github.com/jpsutton/couchbox-iptv) |
| Ember: Jellyfin client that browses like Kodi's Amber skin (vertical menu, list views with a details pane), Quick Connect sign-in | `ember`, built from [ember](https://github.com/jpsutton/ember) |
| ZeroTier (`zerotier-one`, enabled at boot) | `extra` |
| BlueZ, CEC (`libcec`), PipeWire, NetworkManager | `extra` |
| HDMI/DisplayPort audio as the default output when present (a default you pick still wins) | `couchbox-base` (WirePlumber rule) |
| VA-API driver and microcode, picked by CPU vendor | installer |
| Time zone from the network's location, at install and every login (see [time-zone.md](time-zone.md)) | installer, `couchbox-base` (`couchbox-timezone`) |
| HDMI off after 10 idle minutes, never system suspend | `couchbox-base` (PowerDevil) |
| Home screen shows only the app tiles and Settings; Konsole is installed without a tile (Ctrl+Alt+T opens it) | `couchbox-base` (`/etc/couchbox/visible-apps`) |
| Bluetooth pairing agent that accepts and trusts remotes | `couchbox-base` (`couchbox-bt-agent`) |
| Short Home/Menu go to the app; long Home shows the Bigscreen launcher, long Menu the home overlay (Tasks page: hold OK to close an app); OK and Menu remapped for apps | `fire-blaster` (`[hold]`, `[remap]`), `couchbox-base` (KWin script, shortcut defaults) |
| fire-blaster (remote grab, long-press keys; IR once a blaster is fitted) | `packages/fire-blaster`, built from `../fire-blaster` |
