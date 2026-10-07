# The home screen

The home screen shows one row, Applications, which Bigscreen sorts by name. It
lists only the apps in `/etc/couchbox/visible-apps`: Ember, Kodi, Plezy,
YouTube, IPTV, Konsole and Bigscreen Settings. couchbox ships no Bigscreen favorites, so the
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

Bigscreen can't show the apps as a grid. The [roadmap](roadmap.md) has notes
from a trial of a grid layout.
