# Upstream bugs

Bugs in upstream projects found while building couchbox. Each one has a
couchbox workaround; remove the workaround when the upstream fix ships.

To add a bug, add a row to the summary and a section below it. When you file
one, set its status and put the bug link in its section.

Last updated: 2026-09-29

## Summary

| # | Bug | Project, version | Impact | couchbox workaround | Status |
|---|---|---|---|---|---|
| 1 | Home, Menu and Settings shortcuts never registered | plasma-bigscreen 6.7.5 | High | KWin script `couchbox-home` | Not filed |
| 2 | Settings app loses focus after a sub-page closes | plasma-bigscreen 6.7.5 | High | Home closes Settings (`couchbox-home`) | Not filed |
| 3 | Selection accepts only Return, not keypad Enter | plasma-bigscreen 6.7.5 and master | High | hwdb remap `KEY_KPENTER` to `KEY_ENTER` | Not filed |
| 4 | envmanager rewrites the app blacklist at every login | plasma-bigscreen 6.7.5 | Medium | Kiosk lock `blacklist[$i]` in `/etc/xdg` | Not filed |
| 5 | Bluetooth settings register no pairing agent | plasma-bigscreen 6.7.5 | High | `couchbox-bt-agent` service | Not filed |
| 6 | Settings window reports the webapp desktop file | plasma-bigscreen 6.7.5 | Low | None needed | Not filed |

## 1. Home, Menu and Settings shortcuts never registered

In Bigscreen 6.7.5, Home does nothing from anywhere, because Bigscreen's own
global shortcuts never reach kglobalaccel.

- **Where:** `containments/homescreen/plugin/shortcuts.cpp` calls
  `KGlobalAccel::setGlobalShortcut` for "Toggle Bigscreen Home Screen"
  (`Qt::Key_HomePage`), "Toggle Bigscreen Tasks Overview" (`Qt::Key_Menu`) and
  "Toggle Bigscreen Settings" (`Qt::Key_Settings`).
- **Observed:** none of the three appears under any kglobalaccel component,
  including `plasmashell`, or in `~/.config/kglobalshortcutsrc`. The
  plasmashell log shows no error.
- **Repro:** start a Bigscreen session, open any app, and press a key that
  sends `KEY_HOMEPAGE`. Nothing happens. Then list the shortcut names of
  `/component/plasmashell` on `org.kde.kglobalaccel` over D-Bus.
- **couchbox workaround:** KWin script `couchbox-home` registers `Home Page`
  itself and minimizes app windows, as `tasksModel.minimizeAllTasks()` would.
- **Open question:** Menu and Settings are dead too, and couchbox covers only
  Home. Should couchbox also bind Menu to the tasks overview?

## 2. Settings app loses focus after a sub-page closes

After Back closes a sub-page in Bigscreen Settings, no key works in the
window, Back included, so a remote cannot leave it.

- **Where:** `settingsapp/qml/Main.qml`, `popPage()`. After
  `pageStack.pop()` it calls `pageStack.currentItem.forceActiveFocus()`. That
  item passes focus to nothing that takes keys. `Bigscreen.BackHandler.onActivated: hideOverlay()`
  is attached only to the sidebar (`ConfigWindowSidebar`), so Back from the
  page never reaches it.
- **Observed:** KWin still reports Bigscreen Settings as the active window,
  and its main thread is idle, not hung. Alt+F4 recovers.
- **Repro:** open Settings, then Bluetooth, and pair a device so the pairing
  pane opens on the right. Press Back to close it, then press any key.
- **couchbox workaround:** `couchbox-home` closes the Settings window on Home
  instead of minimizing it.
- **Suggested fix:** after the pop, move focus to the sidebar or to a
  focusable child of the page, and handle Back on the page as well.

## 3. Selection accepts only Return, not keypad Enter

Remotes whose OK button sends keypad Enter can move around the home screen but
cannot launch anything.

- **Where:** about 15 handlers check only `Qt.Key_Return` or
  `Keys.onReturnPressed`, in both 6.7.5 and master (checked at `b7ad478`).
  Examples: `components/bigscreenplugin/qml/AbstractDelegate.qml`,
  `controls/Button.qml`, `controls/ButtonDelegate.qml`,
  `containments/homescreen/package/contents/ui/launcher/delegates/IconDelegate.qml`,
  `homeoverlay/TaskDelegate.qml`.
- **Observed:** the Amazon Alexa Voice Remote (Bluetooth, vendor `0171`,
  product `0413`) sends HID usage `0x70058` for OK. That is `KEY_KPENTER`,
  which reaches Qt as `Key_Enter`.
- **couchbox workaround:** `70-couchbox-remotes.hwdb` maps
  `KEYBOARD_KEY_70058=enter` on every USB and Bluetooth HID device.
- **Suggested fix:** accept `Qt.Key_Enter` wherever `Qt.Key_Return` is
  accepted, for example by adding `Keys.onEnterPressed` next to each
  `Keys.onReturnPressed`. This is a mechanical change.

## 4. envmanager rewrites the app blacklist at every login

A distribution cannot hide apps from the Bigscreen home screen with
`/etc/xdg/applications-blacklistrc`, because envmanager overrides it at every
login.

- **Where:** `envmanager/settings.cpp`, `applyBigscreenConfiguration()`,
  writes `APPLICATIONS_BLACKLIST_DEFAULT_SETTINGS` from `envmanager/config.h`
  to `~/.config/plasma-bigscreen/applications-blacklistrc`. The session
  launcher (`bin/plasma-bigscreen-wayland.in`) puts `~/.config/plasma-bigscreen`
  ahead of `/etc/xdg` in `XDG_CONFIG_DIRS`, so that file wins.
- **Mismatch:** a comment in `config.h` says these entries are written only
  if not already defined, but `writeKeys()` writes every key unconditionally.
- **couchbox workaround:** `couchbox-update-app-blacklist` writes
  `blacklist[$i]=` (KDE Kiosk immutable) to `/etc/xdg/applications-blacklistrc`,
  so later files are ignored for that key.
- **Suggested fix:** make `writeKeys()` skip keys that already have a value in
  the cascaded config, as the comment says, or merge the defaults into the
  existing list.

## 5. Bluetooth settings register no pairing agent

On a Bigscreen install without bluedevil, BlueZ refuses pairing that the
remote starts, so a new remote can fail to pair.

- **Where:** `kcms/bluetooth` has no agent code. The `plasma-bigscreen`
  package does not depend on `bluedevil`, which is what registers the agent in
  a desktop Plasma session.
- **Observed:** bluetoothd logs
  `src/device.c:new_auth() No agent available for request type 2`, then
  `device_confirm_passkey: Operation not permitted`. Pairing started from the
  Settings page can still succeed, because BlueZ completes host-started "just
  works" pairing without an agent, but devices paired that way are not marked
  trusted.
- **couchbox workaround:** `couchbox-bt-agent`, a system service that
  registers a `NoInputNoOutput` default agent. It accepts requests and trusts
  every device that pairs.
- **Suggested fix:** register an agent from the Bluetooth module or the shell.
  A confirmation dialog alone is not enough, since the remote being paired
  cannot answer it.

## 6. Settings window reports the webapp desktop file

KWin sees Bigscreen Settings as `org.kde.plasma-bigscreen-webapp`, the web-app
viewer's desktop file, not the settings app's own.

- **Observed:** KWin reports `resourceClass` and `desktopFileName` as
  `org.kde.plasma-bigscreen-webapp` for the window titled "Bigscreen
  Settings". The app's own desktop file is
  `org.kde.plasma.bigscreen.settings.desktop`.
- **Effect:** task lists and window rules cannot tell Settings apart from web
  apps. couchbox has to match the Settings window by its title, which breaks
  in other languages.
- **couchbox workaround:** none needed yet; `couchbox-home` matches on the
  caption.
- **Not checked:** where the settings app sets its desktop file name.
