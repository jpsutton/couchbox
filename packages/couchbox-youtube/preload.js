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
// 3. Leave Shorts out ([YouTube] HideShorts, on by default): the TV app's
//    page data arrives as JSON, and Shorts tiles (TILE_STYLE_YTLR_SHORTS, or
//    opening a reelWatchEndpoint), Shorts grids and the rows they leave empty
//    are dropped before the app sees them.
'use strict';

const { contextBridge } = require('electron');

const arg = process.argv.find(a => a.startsWith('--couchbox-block-codecs='));
const blocked = arg ? arg.split('=')[1].split(',').filter(Boolean) : [];
const hideShorts = process.argv.includes('--couchbox-hide-shorts=true');

if (hideShorts) {
  contextBridge.executeInMainWorld({
    func: () => {
      const isReel = cmd => !!cmd && typeof cmd === 'object' && JSON.stringify(cmd).includes('"reelWatchEndpoint"');
      const isShort = item => {
        if (!item || typeof item !== 'object') return false;
        const tile = item.tileRenderer;
        if (tile && (tile.style === 'TILE_STYLE_YTLR_SHORTS' || isReel(tile.onSelectCommand))) return true;
        if (item.reelItemRenderer || item.shortsLockupViewModel) return true;
        const grid = item.gridRenderer;
        return !!(grid && grid.style && /SHORTS/.test(String(grid.style.type || grid.style)));
      };
      // A row whose items are all gone.
      const isEmptyRow = item => {
        const shelf = item && item.shelfRenderer;
        const list = shelf && shelf.content && (shelf.content.horizontalListRenderer || shelf.content.gridRenderer);
        return !!(list && Array.isArray(list.items) && list.items.length === 0);
      };
      const clean = (node, depth) => {
        if (!node || typeof node !== 'object' || depth > 40) return node;
        if (Array.isArray(node)) {
          for (let i = node.length - 1; i >= 0; i--) {
            if (isShort(node[i])) {
              node.splice(i, 1);
              continue;
            }
            clean(node[i], depth + 1);
            if (isEmptyRow(node[i])) node.splice(i, 1);
          }
          return node;
        }
        for (const key of Object.keys(node)) clean(node[key], depth + 1);
        return node;
      };
      if (window.Response) {
        const json = Response.prototype.json;
        Response.prototype.json = function () {
          return json.call(this).then(value => {
            try {
              clean(value, 0);
            } catch {
              // Leave the page as it came.
            }
            return value;
          });
        };
      }
      const parse = JSON.parse;
      JSON.parse = function (text, reviver) {
        const value = parse.call(this, text, reviver);
        // Only page data (InnerTube responses) is worth walking.
        if (typeof text === 'string' && text.length > 200 && text.includes('Renderer')) {
          try {
            clean(value, 0);
          } catch {
            // Leave the page as it came.
          }
        }
        return value;
      };
    },
  });
}

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
