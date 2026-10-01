# Jellyfin Desktop (removed from couchbox 2026-10-01)

Plezy replaced it as the Jellyfin client: a native UI instead of a wrapper
around jellyfin-web. These are the couchbox-base pieces it used, kept in case
it comes back:

- `org.jellyfin.JellyfinDesktop.desktop`: the home-screen tile, installed to
  `/etc/skel/.local/share/applications` (listed in `_tiles`).
- `couchbox-jellyfin` (`/usr/bin`): starts it in TV mode on the server page,
  working around UPSTREAM-BUGS.md bug 7, and installs the input map.
- `jellyfin-remote.json` (`/usr/share/couchbox`): Menu short press cycles
  subtitles, long press cycles audio.

To restore: move the files back to `packages/couchbox-base`, add them to its
PKGBUILD (`source`, `package()`, `_tiles`, `jellyfin-desktop` in `depends`),
add `org.jellyfin.JellyfinDesktop` to `visible-apps` and `jellyfin-desktop`
to `aur.txt`.
