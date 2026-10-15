// couchbox-youtube in Chromium: runs after page.js in the page's own world,
// with the settings couchbox-youtube-chromium wrote to config.js. Does what
// main.js does in Electron: the page functions, the remote's Back and Home
// keys, no pop-up windows, and a hidden cursor.
/* global couchboxHideShorts, couchboxBlockCodecs */
'use strict';

(() => {
  const config = globalThis.couchboxConfig || {};
  delete globalThis.couchboxConfig;

  if (config.hideShorts) couchboxHideShorts();
  couchboxBlockCodecs(config.blocked || []);

  // Back would leave the single-page TV app for the previous URL; the TV
  // interface goes back a screen on Escape. Home goes to couchbox's start page.
  const escape = type => new KeyboardEvent(type, { key: 'Escape', code: 'Escape', keyCode: 27, which: 27, bubbles: true, cancelable: true });
  addEventListener('keydown', event => {
    if (event.key === 'BrowserBack') {
      event.preventDefault();
      event.stopImmediatePropagation();
      const target = document.activeElement || document.body || document.documentElement;
      target.dispatchEvent(escape('keydown'));
      target.dispatchEvent(escape('keyup'));
    } else if (event.key === 'BrowserHome' && config.home) {
      event.preventDefault();
      event.stopImmediatePropagation();
      location.href = config.home;
    }
  }, true);

  // Stay on YouTube: no pop-up windows.
  window.open = () => null;

  // Hide the cursor while the mouse is idle.
  addEventListener('DOMContentLoaded', () => {
    let timer;
    const show = () => {
      document.documentElement.style.cursor = '';
      clearTimeout(timer);
      timer = setTimeout(() => { document.documentElement.style.cursor = 'none'; }, 2000);
    };
    addEventListener('mousemove', show, { passive: true });
    show();
  });
})();
