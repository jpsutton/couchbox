# Video settings for the hardware

Older and low-power graphics need lighter playback settings. On a Bay Trail
Celeron N2807, mpv's default scaling in Plezy dropped a quarter of the frames
of 1080p H.264 that the GPU itself decodes easily, and software HEVC is barely
real time on its two cores.

Each tweak is its own setting under "Video playback" on the couchbox page in
Bigscreen Settings (`[Video]` in `~/.config/couchboxrc`):

| Setting | What it changes |
|---|---|
| Plezy picture scaling: Fast | bilinear scalers, no dithering, in Plezy's mpv.conf setting (a marked block; other lines stay) |
| Ask the server to convert: HEVC, HEVC 10-bit, AV1, VP9 | Plezy's refused codecs (HEVC, AV1; Plezy 2.22+), Jellyfin for Kodi's transcode options, JellyCon's force-transcode options |

`couchbox-video-profile` (in `couchbox-base`) picks the defaults once, at the
first login (a user service). It reads what the GPU decodes from `vainfo`. A
GPU without hardware HEVC decode counts as low-power: Fast scaling, and the
server converts every codec the GPU can't decode. Other GPUs keep the clients'
own defaults. Nothing resets the settings later, so changes made on the page
or inside Plezy or Kodi stay; "Detect hardware again" on the page re-runs the
probe. A change on the page reaches a client that is running once it exits,
because both rewrite their settings files while they run.

## GPU clock on Bay Trail and Cherry Trail

With the GPU's clock floor at the hardware minimum (187 MHz on the N2807),
these GPUs' clock governor never raises the clock for compositing video:
each frame is a short burst, so the GPU looks mostly idle, but at 187 MHz
the burst often misses the refresh deadline. KWin then misses refreshes:
Ember's 29.97 fps Live TV got about 52 of 60 a second, with frames dropped
and late.

`couchbox-power-profile` (the power-saver service in `couchbox-base`) raises
the floor to RP1 (312 MHz on the N2807) while the screen is on, and drops it
back to the minimum while the screen sleeps. With that floor the governor
ramps up and down as it should, and all 60 refreshes make it; a 646 MHz
floor did no better. It is a floor, not a fixed clock, and an idle GPU still
powers down. It applies only to Bay Trail and Cherry Trail (GPUs that report
`gt_vlv_rpe_freq_mhz` in sysfs), so other hardware is untouched.
