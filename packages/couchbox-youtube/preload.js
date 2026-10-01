// couchbox-youtube preload, run in the page's own world before YouTube's
// scripts (contextBridge.executeInMainWorld):
//
// 1. Answer format queries the way a TV does. YouTube's TV app probes
//    MediaSource.isTypeSupported with extra parameters, including impossible
//    ones (width=99999, framerate=9999, eotf=catavision). Chromium ignores the
//    parameters and says yes to everything; YouTube then treats the answers as
//    unreliable and caps playback at 720p. Checking them the way a TV runtime
//    (Cobalt) does lifts the cap.
// 2. Hide video codecs the main process decided to block (see blockedCodecs in
//    main.js), so YouTube picks a format this PC decodes well, the way the
//    h264ify extension does.
'use strict';

const { contextBridge } = require('electron');

const arg = process.argv.find(a => a.startsWith('--couchbox-block-codecs='));
const blocked = arg ? arg.split('=')[1].split(',').filter(Boolean) : [];

contextBridge.executeInMainWorld({
  args: [blocked],
  func: codecs => {
    const patterns = { vp9: /vp0?9/i, av1: /av01|\bav1\b/i };
    const isBlocked = type => typeof type === 'string' && codecs.some(c => patterns[c] && patterns[c].test(type));

    // What this box can play. 4K is allowed for codecs the GPU decodes
    // (blocked ones never get this far); YouTube picks a size for the screen.
    const LIMITS = { width: 3840, height: 2160, framerate: 60, bitrate: 100e6, channels: 8 };
    const VALUES = {
      eotf: ['bt709'], // SDR only: the TV path has no HDR
      cryptoblockformat: ['subsample'],
      'decode-to-texture': ['true', 'false'],
      tunnelmode: ['false'],
      experimental: ['allowed'],
    };
    // false when a parameter is invalid or beyond the box; otherwise the bare
    // MIME type (codecs only) for the browser to judge.
    const checkParams = type => {
      const [mime, ...params] = type.split(';').map(s => s.trim());
      const kept = [mime];
      for (const param of params) {
        const [key, raw = ''] = param.split('=').map(s => s.trim());
        const value = raw.replace(/^"|"$/g, '');
        const name = key.toLowerCase();
        if (name === 'codecs') {
          kept.push(param);
        } else if (name in LIMITS) {
          const n = Number(value);
          if (!Number.isFinite(n) || n <= 0 || n > LIMITS[name]) return false;
        } else if (name in VALUES) {
          if (!VALUES[name].includes(value.toLowerCase())) return false;
        }
        // Any other parameter: no opinion, leave it to the browser's answer.
      }
      return kept.join('; ');
    };

    for (const MS of [window.MediaSource, window.ManagedMediaSource]) {
      if (!MS) continue;
      const supported = MS.isTypeSupported.bind(MS);
      MS.isTypeSupported = type => {
        if (typeof type !== 'string' || isBlocked(type)) return false;
        const bare = checkParams(type);
        return bare !== false && supported(bare);
      };
    }
    const canPlayType = HTMLMediaElement.prototype.canPlayType;
    HTMLMediaElement.prototype.canPlayType = function (type) {
      return isBlocked(type) ? '' : canPlayType.call(this, type);
    };
    if (navigator.mediaCapabilities) {
      const decodingInfo = navigator.mediaCapabilities.decodingInfo.bind(navigator.mediaCapabilities);
      navigator.mediaCapabilities.decodingInfo = config =>
        isBlocked(config && config.video && config.video.contentType)
          ? Promise.resolve({ supported: false, smooth: false, powerEfficient: false })
          : decodingInfo(config);
    }
  },
});
