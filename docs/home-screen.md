# The home screen

The home screen shows one row, Applications, which Bigscreen sorts by name. It
lists only the apps in `/etc/couchbox/visible-apps`: Ember, YouTube, IPTV and
Bigscreen Settings. Konsole is installed but hidden; Ctrl+Alt+T on a keyboard
opens it. couchbox ships no Bigscreen favorites, so the
Favorites row, which appears only when it has entries, stays hidden. The
Recent row appears only when app-usage history exists, so
`/etc/xdg/kactivitymanagerd-pluginsrc` turns that history off
(`what-to-remember=2`).

A tile that needs its own launcher or arguments overrides the app's `.desktop`
file under the same file ID, in `~/.local/share/applications` (copied from
`/etc/skel`). The ID has to match the window's app ID: Bigscreen raises a
running app only when they match, and otherwise launches it again. No tile
needs one now (Kodi's and Plezy's went with them in couchbox-base 0.12.3);
YouTube ships its own `.desktop` file in `couchbox-youtube`. To add an app,
add its desktop file ID to `visible-apps`; if it needs an override, install a
`<app id>.desktop` file into `/etc/skel/.local/share/applications` from
`couchbox-base`.

Bigscreen can't show the apps as a grid. The [roadmap](roadmap.md) has notes
from a trial of a grid layout.
