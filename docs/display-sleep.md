# Idle display-off

After 10 minutes with no input, PowerDevil turns the HDMI output off (DPMS).
The TV sees "no signal" and goes to sleep on its own. A remote key turns the
output back on. Most TVs stay asleep after that, so turn the TV back on with
its power key (fire-blaster sends it as IR). The box itself never suspends,
because a sleeping PC drops the Bluetooth remote and ZeroTier.

Two settings make this work, both installed to `/etc/xdg`:

- `plasmabigscreenrc` sets `pmInhibitionEnabled=false`. Bigscreen holds a
  system-wide power inhibit by default, and that inhibit blocks display-off
  completely. You can switch it back on under Bigscreen Settings, in the
  "Power inhibition" option.
- `powerdevilrc` sets the timeout, disables dimming and sets
  `AutoSuspendAction=0`. To change the timeout, edit
  `TurnOffDisplayIdleTimeoutSec`.

Playback keeps the screen on. Plezy holds an inhibit through the desktop
portal (`org.freedesktop.portal.Inhibit`), Kodi holds one through Wayland
idle-inhibit, and Ember holds `org.freedesktop.ScreenSaver.Inhibit`.
