# Upstream bugs

Bugs in upstream projects found while building couchbox. Each one has a
couchbox workaround; remove the workaround when the upstream fix ships.

To add a bug, add a row to the summary and a section below it. When you file
one, set its status and put the bug link in its section.

Last updated: 2026-10-03

## Summary

| # | Bug | Project, version | Impact | couchbox workaround | Status |
|---|---|---|---|---|---|
| 1 | Home and Menu bound globally, so apps never get those keys (first thought: never registered) | plasma-bigscreen 6.7.5 | Medium | Bigscreen's bindings moved off Home/Menu; fire-blaster long press sends Meta chords | Not filed |
| 2 | Settings app loses focus after a sub-page closes | plasma-bigscreen 6.7.5 | High | Home closes Settings (`couchbox-home`) | Not filed |
| 3 | Selection accepts only Return, not keypad Enter | plasma-bigscreen 6.7.5 and master | High | fire-blaster `[remap]` `KEY_KPENTER` to `KEY_ENTER` | Not filed |
| 4 | envmanager rewrites the app blacklist at every login | plasma-bigscreen 6.7.5 | Medium | Kiosk lock `blacklist[$i]` in `/etc/xdg` | Not filed |
| 5 | Bluetooth settings register no pairing agent | plasma-bigscreen 6.7.5 | High | `couchbox-bt-agent` service | Not filed |
| 6 | Settings window reports the webapp desktop file | plasma-bigscreen 6.7.5 | Low | None needed | Not filed |
| 7 | TV mode lost: native shell not injected after the server chooser | jellyfin-desktop 2.0.0, qt6-webengine 6.11.2 | High | `couchbox-jellyfin` starts on the server page | Moot: Jellyfin Desktop removed from couchbox 2026-10-01 |
| 8 | AUR build links the wrong CEF major and hangs; no Vulkan dependency | jellium-desktop-git (AUR), 0.r1155.14dc084 | High | Own `packages/jellium-desktop` with the pinned CEF; installer adds Vulkan drivers | Not filed |
| 9 | Web view keeps no keyboard focus after another window steals it | jellium-desktop 0.r1155.14dc084 | Low | KWallet disabled (the trigger seen); restart the app | Not filed |
| 10 | Missing `python-typing_extensions` dependency; add-on fails to load | kodi-addon-jellyfin 2.2.0-1 (AUR) | High | `couchbox-base` depends on `python-typing_extensions` | Not filed |
| 11 | Home-screen favorites appear in arbitrary order | plasma-bigscreen 6.7.5 (fixed on master) | Low | Not needed: couchbox no longer ships favorites | Fixed upstream |
| 12 | GUI deadlock in the PipeWire audio sink while listing devices | kodi 21.3-12 | High | Tile runs `kodi --audio-backend=pulseaudio` | Not filed |
| 13 | Home Page and media keys reach the page as unidentified keys | jellium-desktop 0.r1155.14dc084 | Medium | Patch `0001-map-xf86-browser-and-media-keys.patch` | Not filed |
| 14 | "Toggle Bigscreen Tasks Overview" shortcut has no handler | plasma-bigscreen 6.7.5 | Medium | Long Menu sends the home overlay's default Meta+O; tasks shortcut cleared | Not filed |
| 15 | Opening a named PulseAudio sink takes ~31 s; playback stalls | kodi 21.3-12, pipewire 1.6.9 | High | Keep Kodi on the Default audio device | Not filed |
| 16 | Media keys only reach MPRIS players; Kodi gets nothing | plasma-workspace 6.7.5 (mediacontrol) | Medium | `mediacontrol` bindings cleared in `/etc/xdg/kglobalshortcutsrc` | Not filed |
| 17 | Play/Pause key only plays, never pauses, on Linux | plezy 2.21.0, 2.22.0 | Medium | Patch `packages/plezy-couchbox/0002-linux-play-pause-key-toggles.patch` (in `plezy-couchbox`) | [edde746/plezy#2552](https://github.com/edde746/plezy/pull/2552) |
| 18 | Home key does nothing; no way back to the Home tab from a remote | plezy 2.21.0, 2.22.0 | Medium | Patch `packages/plezy-couchbox/0001-home-key-returns-to-home-tab.patch` (in `plezy-couchbox`) | PR in preparation |
| 19 | UI too small on a TV from a desktop; Display Scale is car-only | plezy 2.21.0, 2.22.0 | Medium | Patch `packages/plezy-couchbox/0003-desktop-display-scale.patch` (in `plezy-couchbox`) | PR in preparation |
| 20 | Card labels use fixed font sizes; no text size setting | plezy 2.21.0 | Low | Display Scale 1.75x (bug 19) instead; Text Size patch dropped | Not filed |
| 21 | Random segfault starting Python add-ons (thread-state race in CPythonInvoker) | kodi 21.3-12, python 3.14.7 | Medium | None yet; relaunch | Known upstream ([xbmc#27025](https://github.com/xbmc/xbmc/issues/27025)); fixed in v22 only |
| 22 | Remote Back does not close the time zone, time and date pickers | plasma-bigscreen 6.7.5 and master | Low | None yet; use the on-screen Back button. couchbox sets the time zone automatically | Not filed |
| 23 | Stop key does nothing in the video player | plezy 2.22.0 | Low | Patch `packages/plezy-couchbox/0004-media-stop-key.patch` (in `plezy-couchbox`); fire-blaster `[remap]` `KEY_STOP` to `KEY_STOPCD` | Not filed |

## 1. Home and Menu are bound globally, so apps never get those keys

Bigscreen binds plain Home Page ("Toggle Bigscreen Home Screen") and Menu
("Toggle Bigscreen Tasks Overview") as global shortcuts. KWin takes a global
shortcut before any app sees it, so Kodi's `<homepage>` (its own home screen)
and Kodi's or Jellyfin's Menu key never fire.

- **Where:** `containments/homescreen/plugin/shortcuts.cpp` calls
  `KGlobalAccel::setGlobalShortcut` with `Qt::Key_HomePage`, `Qt::Key_Menu`,
  `Qt::Key_Settings` and `Meta+O`.
- **Correction:** this entry first said the shortcuts never register. On
  2026-09-28 the plasmashell component listed none of them, but by 2026-09-29
  all four were registered and active. The likely cause is that couchbox's own
  KWin script held plain Home Page at the time, and plasmashell's registration
  succeeded once it was released. Not confirmed.
- **Suggestion:** give TV apps a way to handle Home and Menu themselves, for
  example system actions on a long press only, or an opt-out per app.
- **couchbox workaround:** `/etc/xdg/kglobalshortcutsrc` sets Bigscreen's
  Home Screen and Tasks Overview actions to none. fire-blaster sends
  Meta+Home Page on a long Home and Meta+O (the home overlay's default) on a
  long Menu; the `couchbox-home` KWin script binds Meta+Home Page. Short presses reach the
  app. On a box upgraded from an earlier couchbox, existing saved assignments
  win over `/etc/xdg`, so they were changed once with kglobalaccel's
  `setForeignShortcutKeys`.

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
- **couchbox workaround:** fire-blaster's `[remap]` sends the remote's
  `KEY_KPENTER` as `KEY_ENTER` (`/etc/fire-blaster/config.toml`). Until
  2026-09-29 this was a udev hwdb remap on every HID device.
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

## 7. TV mode lost: native shell not injected after the server chooser

Jellyfin Desktop 2.0 opens the server's web client in the desktop layout even
with `--tv` and `"layout": "tv"`, so the arrow keys scroll the page instead of
moving between items.

- **Where:** `src/ui/webview.qml` injects the native-shell script
  (`SystemComponent::getNativeShellScript()`, which sets `window.jmpInfo` and
  `window.NativeShell`) as a `WebEngineScript.DocumentCreation` user script.
  The first page is the bundled chooser,
  `qrc:///web-client/extension/find-webclient.html`, which then navigates to
  `http://<server>/web/`.
- **Observed:** on the chooser page the script runs (it reads the saved server
  from `jmpInfo`). On the server page `window.jmpInfo` and
  `window.NativeShell` are undefined and `<html>` has class `layout-desktop`.
  After a reload of the same URL both exist and the class is `layout-tv`.
  Setting `path.startupurl_desktop` to the server's `/web/` URL, so the server
  page is the first load, also works.
- **Likely cause:** the user script is not applied after the cross-scheme
  navigation from `qrc:` to `http:` (a new renderer process), in Qt WebEngine
  6.11.2. Not checked on 6.10.
- **Repro:** Jellyfin Desktop 2.0.0, Arch, qt6-webengine 6.11.2, Jellyfin
  server 10.11.11. Launch with `--tv --remote-debugging-port=9222`, then
  evaluate `typeof window.NativeShell` on the server page.
- **couchbox workaround:** the tile runs `couchbox-jellyfin`, which sets
  `startupurl_desktop` to the saved server when it answers, and back to
  `bundled` when it doesn't, then starts `jellyfin-desktop --fullscreen --tv`.
  The very first launch, before any server is saved, still goes through the
  chooser, so that first session is in the desktop layout.
- **Upstream status:** the Qt client is deprecated in favor of an SDL and CEF
  rewrite ([Arch forum](https://bbs.archlinux.org/viewtopic.php?id=312933)),
  so a fix for 2.0 is unlikely.
- **Related, not reproduced here:** the same thread reports that video does
  not play ("flashes white") on Wayland with Intel graphics under
  qt6-webengine 6.11.0, fixed there by downgrading to 6.10.2. On the NUC6i5SY
  (Iris 540) with 6.11.2, video plays correctly (2026-09-29).

## 8. AUR build links the wrong CEF major and hangs; no Vulkan dependency

The AUR's `jellium-desktop-git` builds, but on current Arch the app hangs on
its loading spinner. Separately, it exits at once on machines without a
Vulkan driver.

- **Wrong CEF:** the PKGBUILD runs `cargo xtask build --cef-path /usr/lib/cef`,
  which links Arch's system `cef` (152.0.6). The code pins CEF 151
  (`cef = { version = "=151" }` in `src/Cargo.toml`), and upstream's AppImage
  bundles 151.3.16. With 152, `CefInitialize` never returns: the log stops at
  `[FLOW] calling CefInitialize...`, the main thread waits in
  `pthread_cond_wait` inside `libcef.so`, and no renderer process starts. The
  AppImage at the same commit returns from `CefInitialize` in 440 ms.
- **Missing Vulkan dependency:** the shell overlay uses wgpu with only
  `Backends::VULKAN` on Linux (`src/gpu_paint/src/context.rs`). Without a
  Vulkan driver it logs
  `gpu_paint: device init failed: no usable adapter available` and exits with
  status 1. Neither the `-git` nor the `-bin` PKGBUILD depends on a Vulkan
  driver.
- **Also:** `jellium-desktop-bin` declares `provides`/`conflicts` on
  `jellyfin-desktop` and links `/usr/bin/jellyfin-desktop` to Jellium, so it
  cannot be installed next to Jellyfin Desktop.
- **couchbox workaround:** `packages/jellium-desktop` builds commit
  `14dc0845` without `--cef-path`, so `cargo xtask` downloads the pinned CEF
  and stages it in `/opt/jellium-desktop`. `couchbox-install` adds
  `vulkan-intel` or `vulkan-radeon` by CPU vendor.
- **Suggested fix:** in the AUR package, build with the pinned CEF (or pin the
  `cef` dependency to the matching major), and depend on `vulkan-driver`.
  Maintained by Andrew Rabert, the upstream author.

## 9. Web view keeps no keyboard focus after another window steals it

If another window takes focus while Jellium starts, keys stop reaching the
page even after Jellium is the active window again.

- **Observed:** KWallet's first-use wizard opened full screen over Jellium.
  After it closed, KWin reported Jellium as the active window, but in the page
  `document.hasFocus()` was `false`, and neither keyboard nor remote input did
  anything. Minimizing and restoring the window through KWin did not help. A
  restart did: `document.hasFocus()` was `true`.
- **Where to look:** `src/wayland/src/input.rs`, the `KeyboardHandler`
  `enter` handler and `reconcile_keyboard_focus()`, which decide when
  `set_focus(true)` reaches the CEF browser host.
- **couchbox workaround:** `/etc/xdg/kwalletrc` disables KWallet, which
  removes the popup that triggered it. Any other window that takes focus
  could still cause it.

## 10. kodi-addon-jellyfin: missing python-typing_extensions dependency

The Jellyfin for Kodi add-on fails to start, and browsing it shows
`GetDirectory - Error getting plugin://plugin.video.jellyfin/`.

- **Observed:** Kodi logs `ModuleNotFoundError: No module named 'typing_extensions'`
  from `jellyfin_kodi/helper/exceptions.py`, line 2
  (`from typing_extensions import deprecated`).
- **Where:** the AUR PKGBUILD depends on `kodi`, `python-kodi_six`,
  `python-dateutil`, `python-requests`, `python-six` and
  `python-websocket-client`, but not `python-typing_extensions`. The add-on's
  `addon.xml` does list `script.module.typing_extensions`. On Arch, system
  Python packages stand in for these Kodi modules, so the PKGBUILD has to
  carry every one of them.
- **couchbox workaround:** `couchbox-base` depends on `python-typing_extensions`.
- **Suggested fix:** add `python-typing_extensions` to the AUR package's
  `depends`.

## 11. Home-screen favorites appear in arbitrary order

The tiles do not follow the order in `~/.config/bigscreen-favs`. couchbox
writes Jellyfin, Jellium, Kodi as `[Favs][0]` to `[Favs][2]`; a fresh install
showed Jellium, Kodi, Jellyfin.

- **Where:** 6.7.5 `containments/homescreen/plugin/favslistmodel.cpp`,
  `loadFavsList()`, iterates `grp.groupList()` as KConfig returns it, which is
  not in index order. The order can differ between boots.
- **Upstream:** already fixed on master: `loadFavsList()` sorts the group
  names numerically (`sortStringifiedInt`) and warns "Favorites sorting might
  be incorrect" when it can't.
- **couchbox workaround:** not needed. couchbox stopped shipping favorites
  (the row is hidden when empty); the Applications row is sorted by name.

## 12. Kodi: GUI deadlock in the PipeWire audio sink while listing devices

Kodi's screen froze on Settings, System, Audio. It still answered JSON-RPC,
but no input, from the remote or `Input.Down` over JSON-RPC, moved the focus.

- **Observed (backtrace, kodi 21.3-12, pipewire 1.6.9):**
  - Main thread: `CGUIControlListSetting::Update` ->
    `ActiveAE::CActiveAESettings::SettingOptionsAudioDevicesFiller` ->
    `CAESinkPipewire::EnumerateDevicesEx` -> `pw_thread_loop_lock()`, waiting
    forever.
  - `ActiveAE` thread: `CAESinkPipewire::EnumerateDevicesEx`, in
    `pthread_cond_timedwait` inside libspa, waiting for PipeWire.
  - `pipewire` loop thread: `KODI::PIPEWIRE::CPipewireRegistry::OnGlobalRemoved`,
    blocked on a Kodi mutex.
- **Likely cause:** lock-order inversion. A PipeWire object is removed while
  Kodi enumerates devices; the removal callback on the loop thread needs a
  lock the enumerating thread holds, and the enumeration waits for the loop
  thread. On an HTPC the removal is plausibly the TV's HDMI audio sink going
  away when the TV sleeps or the output blanks.
- **Repro (not yet reliable):** open Settings, System, Audio around the time
  an audio device appears or disappears.
- **Evidence:** full `thread apply all bt` saved on the NUC at
  `/root/kodi-deadlock-bt.txt`.
- **couchbox workaround:** the Kodi tile starts `kodi --audio-backend=pulseaudio`,
  which uses Kodi's PulseAudio sink through `pipewire-pulse` instead of the
  native PipeWire sink.
- **Recovery:** Kodi cannot quit normally from this state; `kill -9` it.

## 13. Jellium: Home Page and media keys reach the page as unidentified keys

A remote's Home key does nothing in Jellium, while the same key works in
Jellyfin Desktop, where it goes to jellyfin-web's home screen.

- **Where:** `src/linux_util/src/keysym.rs`, `keysym_to_vkey()`, maps only
  standard keyboard keysyms to Windows VK codes; everything else returns 0.
  `src/linux_util/src/input.rs` special-cases only `XF86Back` and
  `XF86Forward` (history navigation), which is why Back works.
- **Effect:** with VK 0, Chromium delivers an unidentified key, so
  jellyfin-web's `BrowserHome` (home), `BrowserSearch` and media-key bindings
  never fire.
- **couchbox workaround:** a patch in `packages/jellium-desktop` maps
  `XF86HomePage`, `XF86Search`, `XF86AudioPlay/Pause/Stop/Next/Prev` to
  `VK_BROWSER_HOME`, `VK_BROWSER_SEARCH`, `VK_MEDIA_*` and `VK_PAUSE`.
- **Suggested fix:** the same mapping upstream; the patch is small enough to
  send as is. Upstream `main` was still at `14dc084` on 2026-09-29.

## 14. Bigscreen: "Toggle Bigscreen Tasks Overview" shortcut does nothing

The tasks overview shortcut (default Menu) is registered with kglobalaccel
and fires, but nothing happens on screen.

- **Where:** `shell/shortcuts.cpp` emits `toggleTasksOverlay()` when the
  action triggers, but no QML in 6.7.5 connects to that signal. The
  neighbouring home overlay (`toggleHomeOverlay`, default Meta+O) is handled
  by `HomeOverlayWindow.qml`, and its sidebar has a Tasks entry
  (`openTasks()` -> `tasksView.open()`).
- **Repro:** `qdbus6 org.kde.kglobalaccel /component/plasmashell
  org.kde.kglobalaccel.Component.invokeShortcut "Toggle Bigscreen Tasks Overview"`;
  compare with `"Toggle Bigscreen Home Overlay"`, which opens the overlay.
- **couchbox workaround:** `/etc/xdg/kglobalshortcutsrc` clears the tasks
  overview shortcut, and fire-blaster sends Meta+O, the home overlay's
  default shortcut, on a long Menu press.
- **Suggested fix:** connect `toggleTasksOverlay` in the shell QML, e.g. show
  the home overlay and call `openTasks()`, or remove the dead action.

## 15. Kodi: opening a named PulseAudio sink takes ~31 s, playback stalls

With the audio device set to the HDMI sink by name
(`PULSE:alsa_output.pci-0000_00_1f.3.hdmi-stereo`), every stream start hangs:
video freezes a few seconds in while subtitles keep drawing.

- **Where:** Kodi's PulseAudio sink (`CAESinkPULSE::Initialize`) through
  `pipewire-pulse` 1.6.9. Opening the named sink takes about 31 s (log:
  `OpenSink - initialize sink` at 11:25:36, `Opened device ...hdmi-stereo` at
  11:26:07). ActiveAE gives up after 5 s (`ActiveAE::InitSink - failed to
  init`, then `FlushEngine - failed to flush`) and retries forever; the video
  clock waits on audio.
- **Contrast:** `PULSE:Default` opens in ~30 ms and still plays over HDMI,
  because PipeWire's default sink is the HDMI output.
- **Repro:** Settings, System, Audio, Audio output device = the HDMI entry
  (not "Default"); play anything.
- **Recovery:** changing the device while stuck does not unwedge ActiveAE;
  quit and restart Kodi.
- **couchbox workaround:** keep Kodi on the Default device (Kodi's own
  default). Not locked; picking the HDMI entry by hand brings the bug back.
- **To investigate:** whether the delay is Kodi (waiting on a sink-info or
  stream-ready callback that PipeWire answers late) or pipewire-pulse. Bug 12
  (the native PipeWire sink deadlock) may be related.

## 16. Plasma media keys only reach MPRIS players; Kodi gets nothing

Play/Pause, Rewind and Fast Forward on the remote do nothing in Kodi, while
they work in Plezy.

- **Where:** Plasma's Media Controller (`[mediacontrol]` in
  `kglobalshortcutsrc`) binds Media Play, Pause, Next, Previous, Rewind and
  Fast Forward as global shortcuts and forwards them over MPRIS. Global
  shortcuts are consumed, so the focused window never sees the keys. Kodi has
  no MPRIS interface, so the presses go nowhere.
- **couchbox workaround:** `couchbox-base` clears those six `mediacontrol`
  bindings (`/etc/xdg/kglobalshortcutsrc`), so the keys go to the app in
  front. Kodi then handles them itself; Plezy needs bug 17's fix for
  Play/Pause, which is why couchbox ships `plezy-couchbox`.
- **Suggested fix:** Kodi could expose MPRIS; or Plasma could let a key
  through when no MPRIS player is active.

## 17. Plezy: Play/Pause key only plays on Linux

Without Plasma's MPRIS forwarding (bug 16), the remote's Play/Pause key in
Plezy flashes the play disc and does not pause. Fast Forward and Rewind work
(chapter skip).

- **Where:** XKB maps evdev `KEY_PLAYPAUSE` to the `XF86AudioPlay` keysym, so
  Flutter reports `LogicalKeyboardKey.mediaPlay`. Plezy's
  `classifyTransportKey()` (`lib/focus/transport_keys.dart`) treats
  `mediaPlay` as a directed play, which is a no-op while playing. The
  physical key is still `PhysicalKeyboardKey.mediaPlayPause`.
- **Why not remap it:** XKB has no Play/Pause keysym to remap to; every evdev
  play key becomes `XF86AudioPlay`. So the fix has to be in the app.
- **Patch:** `packages/plezy-couchbox/0002-linux-play-pause-key-toggles.patch`
  (against tag 2.22.0). `classifyTransportKey()` takes an optional physical
  key and returns `toggle` for `PhysicalKeyboardKey.mediaPlayPause`. Its
  three callers pass the physical key: the video controls
  (`key_events.dart`), the player screen's remote transport
  (`video_player_screen.dart`) and the music hardware transport
  (`music_hardware_transport.dart`). Dedicated Play and Pause keys stay
  directed, as upstream intends.
- **Status:** see "Plezy pull requests" below.

## 18. Plezy: Home key does nothing

The remote's Home key (evdev `KEY_HOMEPAGE`, Flutter
`LogicalKeyboardKey.browserHome`) does nothing in Plezy, while Kodi and
Jellyfin Desktop use it to go to their own home screen. On couchbox a short
Home press belongs to the app (long Home goes to the Bigscreen launcher).

- **Where:** `lib/screens/main_screen.dart`. Plezy already has a "go to the
  Home tab" action, but only the companion remote's `onHome` command calls
  it; no key handler does.
- **Patch:** `packages/plezy-couchbox/0001-home-key-returns-to-home-tab.patch`
  (against tag 2.22.0). Extracts the `onHome` body into `_goToHomeTab()` and
  adds a `HardwareKeyboard` handler for `browserHome` that pops the profile
  navigator to its first route (closing pushed pages and the player) and then
  calls `_goToHomeTab()`. The handler swallows the key's repeat and release.
  On Android TV and tvOS the system keeps Home, so the handler only runs
  where the app receives the key.
- **Status:** see "Plezy pull requests" below.

## 19. Plezy: UI too small on a TV; Display Scale only on cars

On a 1080p TV (55-60 inch, viewed from 8-10 ft) Plezy's text and controls are
too small, and no setting changes them.

- **Where:** Linux gives Flutter a device pixel ratio of 1 at 1920x1080 (the
  output scale), so the TV layout gets a 1920x1080 logical surface. TV
  platforms report about half that: Android TV at 1080p is typically
  960x540 dp, and Plezy itself renders Apple TV at 2x (`FormFactorScale`,
  `lib/main.dart`). Plezy already has a "Display Scale" setting
  (`automotive_ui_scale`, 1.0 to 2.0), but `FormFactorScale` applies it only
  on Android Automotive, and `appearance_settings_screen.dart` shows the
  slider only there.
- **Why not fix it outside the app:** Plasma's output scale would enlarge
  the Bigscreen shell too. Flutter reads the text scale from the desktop
  portal's `org.gnome.desktop.interface text-scaling-factor`, which
  `xdg-desktop-portal-kde` does not provide. `GDK_SCALE` on Wayland only
  raises the buffer scale; the logical size stays the same.
- **Patch:** `packages/plezy-couchbox/0003-desktop-display-scale.patch`
  (against tag 2.22.0). On desktop, `FormFactorScale` applies the stored
  Display Scale (skipped at 1.0, the existing desktop default), and the
  slider appears under Settings, Appearance, Display.
- **Video plane fix, same patch:** the scaled surface also scales
  MediaQuery's `devicePixelRatio`, and the Linux plugin rounds the ratio it
  is sent into an integer Wayland buffer scale (`mpv_plugin.cc`), so at
  1.75x video filled only part of the screen (1.35x rounded to 1 and hid
  it). `lib/mpv/video.dart` now takes the rect through the ancestor
  transform and sends the view's own ratio; unchanged without a transform.
- **Status:** see "Plezy pull requests" below.

## 20. Plezy: card labels stay small; no text size setting

The titles and captions under tiles use fixed font sizes (13 and 11 logical
px in `lib/widgets/media_card.dart`), and Library Density grows posters but
not these labels. At Display Scale 1.35x they were too small from 8-10 ft.

- **Tried and dropped:** a Text Size setting that multiplied the app's
  `TextScaler` and grew the fixed text bands in `tv_browse_rail.dart`,
  `hub_section.dart`, `cast_member_strip.dart` and the extras strip. On
  the TV it still cut labels off at some sizes: more layouts than those
  reserve fixed space for text. Not worth pursuing upstream as it stood.
- **couchbox workaround:** Display Scale at 1.75x (bug 19), which scales the
  whole layout, so text and the space for it grow together.

## 21. Kodi: random segfault starting Python add-ons

Kodi sometimes crashes right after launch; launching it again works. Seen
twice on the NUC (2026-09-29 16:14 UTC and 2026-10-01 03:34 UTC).

- **Where:** both cores (`coredumpctl`) crash in a `CLanguageInvokerThread`:
  `libpython3.14` `PyEval_RestoreThread` called from
  `CPythonInvoker::execute`, about a second after "Running the
  application", when the service add-ons start (Jellyfin, JellyCon and
  `service.xbmc.versioncheck`). Kodi's crash report:
  `~htpc/kodi_crashlog-20261001_033454.log`.
- **Upstream:** [xbmc#27025](https://github.com/xbmc/xbmc/issues/27025).
  `CPythonInvoker` borrows `PyThreadState` objects owned by other OS
  threads (`execute()`, `onExecutionDone()`, `stop()`), so overlapping
  script starts race. Fixed by
  [xbmc#27320](https://github.com/xbmc/xbmc/pull/27320) in v22 (Alpha 2);
  never backported to Omega, see the request in
  [xbmc#29314](https://github.com/xbmc/xbmc/issues/29314). That report also
  ties it to `<reuselanguageinvoker>true</reuselanguageinvoker>`, which
  only the bundled scrapers set here, not the services that crash.
- **couchbox workaround:** none yet. Options: backport #27320 into a
  couchbox Kodi build, or start fewer Python services at once (e.g.
  disable `service.xbmc.versioncheck`, which has no use on Arch).

## 22. Bigscreen Settings: remote Back does not close the time pickers

In Bigscreen Settings, System, "Adjust date and time", the Timezone, Time
and Date entries each open a full-screen picker with a Back button at the
top. The remote's Back key does nothing there; only selecting the on-screen
Back button closes the picker.

- **Where:** `kcms/bigscreen-settings/ui/DeviceTimeSettingsSidebar.qml`. The
  three pickers are plain `QQC2.Popup`s. Bigscreen handles Back through its
  `BackHandler` attached property (`Qt::Key_Back`, `Qt::Key_Escape` or the
  mouse Back button), and its own `Dialog` control sets
  `BackHandler.enabled: root.visible` and `BackHandler.onActivated:
  root.reject()`. These popups set no `BackHandler`, and a popup's default
  close policy reacts to Escape only, so `Key_Back` from the remote
  (fire-blaster sends `KEY_BACK`) is ignored. Unchanged on master
  (checked 2026-10-03).
- **Fix:** give each popup `Bigscreen.BackHandler.enabled: visible` and
  `Bigscreen.BackHandler.onActivated: close()`, or build them on
  Bigscreen's `Dialog`.
- **couchbox workaround:** none yet. The time zone picker is rarely needed:
  couchbox sets the zone from the network at install and at login.

## 23. Plezy: Stop key does nothing in the video player

The remote's Stop key does nothing while a video plays. Plezy's companion
remote has a Stop command, which leaves the player, but no key handler acts
on the media Stop key.

- **Two parts:** the Media Center remote sends evdev `KEY_STOP`, which XKB
  maps to `Cancel`, not a media key. fire-blaster remaps it to `KEY_STOPCD`
  (`XF86AudioStop`, Flutter's `LogicalKeyboardKey.mediaStop`). Plezy then
  still ignores `mediaStop` in all three key paths: the controls' focus
  handler and the desktop global handler
  (`lib/widgets/video_controls/parts/key_events.dart`), and the screen's
  TV navigation handler (`lib/screens/video_player_screen.dart`).
- **Patch:** `packages/plezy-couchbox/0004-media-stop-key.patch` (against
  tag 2.22.0 plus patches 0001-0003; it touches files 0002 also changes).
  Stop leaves the player the way Back does (`_handleBackButton`, the same
  as the companion remote's `onStop`), on key down only. Branch
  `feat/media-stop-key` on the fork, written against upstream `main`;
  `flutter analyze` and the full test suite pass.
- **Status:** not filed; no upstream PR yet.

## Plezy pull requests

Three separate PRs against https://github.com/edde746/plezy, one per patch,
so each can be reviewed on its own. The patches are diffs
against tag 2.22.0 and apply in any order (they touch different files),
except patch 0004 (bug 23), which applies after 0002.

- **couchbox build:** `packages/plezy-couchbox`, Arch's `plezy` PKGBUILD
  with the three patches in `prepare()`, built into the couchbox repo. It
  provides and conflicts with `plezy` and has its own name, so Arch's
  `plezy` updates never replace it. Drop each patch as its PR is merged, and
  return to Arch's `plezy` when none are left. Tested earlier as a lab build
  (`~/Projects/Personal/plezy-lab/arch`, `pkgrel=1.5`) on the NUC.
- **Testing on the NUC (Alexa Voice Remote, Plasma Bigscreen 6.7.5, Wayland):**
  - Home from a pushed page and from the player: passed 2026-09-29.
  - Play/Pause toggles during video: passed 2026-09-29. Fast Forward and Rewind still
    skip chapters: passed 2026-09-29.
  - Video fills the screen at Display Scale 1.75x: passed 2026-09-29.
  - Display Scale slider shown on desktop and applied live; layout fills
    the screen at 1.75x (the value in use): passed 2026-09-29.
  - Still to cover before opening the PRs: mouse clicks landing correctly
    with Display Scale on (only the remote was used); music playback with Play/Pause;
    a keyboard with a Home key; that the configured play/pause hotkey
    (Space) still works.
- **Checked (patches 1-3 stacked, with the video plane fix):** `flutter
  analyze lib test` is clean; `flutter test` passes (7469 tests).
- **Before opening:** rebase onto upstream `main` (both were written
  against 2.21.0), run `flutter analyze` and the test suite, and follow the
  repo's commit style (conventional commits, e.g. `fix(input): ...`).

### PR 1 draft: Home key returns to the Home tab

> **feat(navigation): Home key returns to the Home tab**
>
> On desktop Linux TV setups (e.g. Plasma Bigscreen with a Bluetooth
> remote), the remote's Home key reaches Plezy as
> `LogicalKeyboardKey.browserHome`, but nothing handles it. This adds a
> `HardwareKeyboard` handler in `MainScreen` that pops the profile
> navigator back to its first route and selects the Home tab, reusing the
> existing companion-remote `onHome` logic (extracted into
> `_goToHomeTab()`).
>
> Android TV and tvOS keep the Home key for the system, so this only
> affects platforms where the app receives it.
>
> Tested on Arch Linux, Plasma Bigscreen 6.7.5 (Wayland), Amazon Alexa
> Voice Remote over Bluetooth.

### PR 2: Play/Pause key toggles on Linux (opened as edde746/plezy#2552)

> **fix(input): treat the Linux Play/Pause key as a toggle**
>
> On Linux, XKB maps the Play/Pause key (evdev `KEY_PLAYPAUSE`) to the
> `XF86AudioPlay` keysym, so Flutter reports `LogicalKeyboardKey.mediaPlay`
> and `classifyTransportKey()` returns a directed `play`. While a video is
> playing, pressing Play/Pause only flashes the play disc. The physical key
> is still `PhysicalKeyboardKey.mediaPlayPause`, so this passes the
> physical key to `classifyTransportKey()` and maps it to `toggle`.
> Dedicated Play and Pause keys stay directed.
>
> This shows up whenever the desktop does not intercept media keys for
> MPRIS, e.g. Plasma with the Media Controller shortcuts cleared so other
> apps (Kodi) can receive them.
>
> Tested on Arch Linux, Plasma 6.7.5 (Wayland), Amazon Alexa Voice Remote
> over Bluetooth.

### PR 3 draft: Display Scale on desktop

> **feat(settings): Display Scale on desktop**
>
> The Display Scale setting (`automotive_ui_scale`) scales the whole UI
> through `FormFactorScale`, but only on Android Automotive. A desktop
> driving a TV from across the room (e.g. Linux with Plasma Bigscreen and
> TV mode forced on) has the same problem: at 1920x1080 with a device pixel
> ratio of 1, text and controls are about half the size a TV platform would
> give them (Android TV reports ~960x540 dp; Plezy renders Apple TV at 2x).
>
> This shows the setting on desktop and applies it there. The desktop
> default stays 1.0, so nothing changes until the slider is moved.
>
> Tested on Arch Linux, Plasma Bigscreen 6.7.5 (Wayland), 1080p TV.
