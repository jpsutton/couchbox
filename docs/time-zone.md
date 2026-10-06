# Time zone

The installer looks the time zone up from the network's public IP address
(GeoIP: `ipinfo.io`, then `ip-api.com`) and offers it; decline it to pick a
region and city. Offline, it asks for a zone (or uses UTC with `--yes`).
`--timezone ZONE` sets one without asking.

After that, `couchbox-timezone` (a user service in `couchbox-base`) repeats
the lookup at every login, so a box that moves follows along. It keeps trying
for several minutes while the network comes up. "Set the time zone
automatically" on the couchbox page in Bigscreen Settings (`[Time] Automatic`
in couchboxrc) turns it off. A zone picked by hand stays put: one picked in
the installer (or with `--timezone`) writes `Automatic=false` to
`/etc/xdg/couchboxrc`, and one changed elsewhere (Bigscreen's own Timezone
picker under System, Adjust date and time) switches it off at the next login.

The lookup sends the box's public address to those services, as any web
request does; turn automatic off if that matters. A polkit rule in
`couchbox-base` lets `wheel` users (`htpc`) change the time zone without a
password (not the clock itself).
