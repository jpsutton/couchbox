// couchbox-youtube Electron preload: the page functions in page.js (which
// the package puts before this file in preload.js), run in the page's own
// world through contextBridge.executeInMainWorld, with the settings the main
// process passes as arguments (see blockedCodecs and hideShorts in main.js).
/* global couchboxHideShorts, couchboxBlockCodecs */

const { contextBridge } = require('electron');

const arg = process.argv.find(a => a.startsWith('--couchbox-block-codecs='));
const blocked = arg ? arg.split('=')[1].split(',').filter(Boolean) : [];
const hideShorts = process.argv.includes('--couchbox-hide-shorts=true');

if (hideShorts) {
  contextBridge.executeInMainWorld({ func: couchboxHideShorts });
}

contextBridge.executeInMainWorld({ args: [blocked], func: couchboxBlockCodecs });
