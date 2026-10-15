# couchbox-rpi: run KWin on the vc4 display device only. The Pi's v3d GPU
# (render only, no outputs) is a separate DRM device; when KWin also opens it,
# it composites there and imports the result into vc4, which can't reach
# buffers above the DMA limit ("swiotlb buffer is full", no picture). Mesa
# still renders with v3d through vc4's kmsro driver.
for card in /sys/class/drm/card[0-9]*; do
  case $(readlink "$card/device/driver") in
    */vc4-drm|*/vc4_drm|*/vc4) export KWIN_DRM_DEVICES=/dev/dri/${card##*/}; break ;;
  esac
done
