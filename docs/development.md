# Working on couchbox

## Tested hardware

couchbox runs on an Intel NUC (Skylake, NUC6i5SYB), and was installed from
the netinstall ISO on a Gigabyte BRIX (Bay Trail Celeron N2807). Installs from
both ISOs also pass in QEMU/OVMF. Not yet tried on AMD hardware.

## Layout

```
aur.txt                   AUR packages to build, in order, with their local deps
packages/couchbox-base/   meta package and appliance config
packages/kodi-addon-couchbox-shuffle/  Kodi context menu on shows and seasons: Shuffle one, Shuffle all
packages/plezy-couchbox/  Plezy with couchbox's patches (Home key, Play/Pause, Display Scale); provides plezy
packages/couchbox-youtube/  YouTube's TV interface (youtube.com/tv) in a fullscreen window on the system electron
packages/couchbox-iptv/     IPTV app and its refresh job, built from github.com/jpsutton/couchbox-iptv at a tag
packages/ember/           Ember, the Jellyfin client, built from github.com/jpsutton/ember at a tag
packages/couchbox-wallpapers/  14 TV-friendly KDE wallpapers; Bigscreen's default slideshow rotates through them
packages/couchbox-settings/  "couchbox" page in Bigscreen Settings (KCM); options in ~/.config/couchboxrc
                          (YouTube codecs, video settings for the hardware)
scripts/build-repo.sh     builds the AUR and local packages in a clean chroot into out/repo
                          (packs ../fire-blaster, or $FIRE_BLASTER_SRC, as fire-blaster's source)
scripts/build-iso.sh      releng profile with a minimal live system; full: plus an offline repo of everything
                          the target needs; net: plus Wi-Fi and network firmware instead
iso/target-packages       what the installer puts on a target, by CPU vendor
iso/airootfs/             files added to both live ISOs, including couchbox-install
iso/airootfs-net/, iso/packages-net.x86_64, iso/net-noextract.conf, iso/net-drop-modules
                          netinstall ISO only: motd and initramfs config, extra packages, and the
                          firmware and kernel modules it leaves out (scripts/*-noextract.sh)
disabled-packages/        kept but not built: jellium-desktop (patched Jellium, off since 2026-09-29),
                          jellyfin-desktop (its tile, TV-mode launcher and remote input map, removed 2026-10-01)
```

## Build

On an Arch host with `devtools`, `archiso`, `pacman-contrib` and `grub` (netinstall ISO only) installed:

```sh
make check   # static checks, no root needed
make repo    # clean-chroot builds into out/repo (asks for sudo)
make iso     # out/couchbox-*.iso
make netiso  # out/couchbox-netinstall-*.iso; needs no `make repo`
```

## Branches and CI

Changes go feature branch -> `staging` -> `release`, each step a pull request.
`staging` is the default branch.

| Event | Workflow | What runs |
|---|---|---|
| PR into `staging` or `release` | `checks` | `scripts/check.sh` (same as `make check`), about a minute |
| PR into `release` | `checks` | also: the PR must come from `staging` |
| PR into `release` | `build` | every package in an `archlinux:base-devel` container (`scripts/ci/build-packages.sh`), and the netinstall ISO in parallel in a privileged one (`scripts/ci/build-iso.sh net`, the `iso` job); both uploaded as artifacts. The full ISO isn't built in CI |
| merge into `release` | `release` | no rebuild: takes the PR's build artifacts, signs the packages and repo database, tags `YYYY.MM.DD`, and publishes a GitHub Release |

Merge staging -> release PRs with **Create a merge commit**: the release
workflow finds the PR's build through the merge commit's second parent, and
refuses to publish if the merged tree differs from what was built.

## Releases

Each release carries the netinstall ISO and the couchbox pacman repo: the
packages, a detached `.sig` for each, and the signed `couchbox.db`. Installed
boxes use it as

```
[couchbox]
SigLevel = Required
Server = https://github.com/jpsutton/couchbox/releases/latest/download
```

trusting the key in `couchbox-keyring` (fingerprint `30DF04A7B6501BD317ADD964250A71E231E76DE0`).
The private key is the `COUCHBOX_GPG_KEY` repository secret; only the release
workflow reads it. To roll a box back, point `Server` at an older release:
`.../releases/download/<tag>`.

## Upstream bugs

[UPSTREAM-BUGS.md](../UPSTREAM-BUGS.md) tracks bugs found in upstream projects,
mostly Plasma Bigscreen, along with the couchbox workaround for each.
