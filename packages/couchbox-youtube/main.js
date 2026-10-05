// couchbox-youtube: YouTube's TV interface (youtube.com/tv) in a fullscreen
// Electron window, for a remote. Runs on the system electron; no npm modules.
'use strict';

const { app, BrowserWindow, session } = require('electron');
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const TV_URL = 'https://www.youtube.com/tv';
// youtube.com/tv only serves the TV interface to TV browsers. LG webOS runs
// YouTube as a web app in its WebAppManager, so a browser is a supported TV
// client there. Samsung Tizen user agents (any version, 6.5 to 9.0) get the
// interface but with a "This device no longer fully supports YouTube" banner
// (tested 2026-10-01).
const USER_AGENT = process.env.COUCHBOX_YOUTUBE_UA
  || 'Mozilla/5.0 (Web0S; Linux/SmartTV) AppleWebKit/537.36 (KHTML, like Gecko) '
  + 'Chrome/120.0.6099.270 Safari/537.36 WebAppManager';
const ALLOWED_HOSTS = /(^|\.)(youtube\.com|google\.com|googlevideo\.com|ytimg\.com|ggpht\.com|gstatic\.com|googleusercontent\.com|youtube-nocookie\.com|accounts\.google\.[a-z.]+)$/;

// A [YouTube] setting in ~/.config/couchboxrc, set from the couchbox page in
// Bigscreen Settings, or [fallback].
function youtubeSetting(key, fallback) {
  const dir = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config');
  let group = '';
  try {
    for (const line of fs.readFileSync(path.join(dir, 'couchboxrc'), 'utf8').split('\n')) {
      const header = line.match(/^\s*\[(.*)\]\s*$/);
      if (header) {
        group = header[1];
        continue;
      }
      const entry = line.match(/^\s*([A-Za-z]+)\s*=\s*(\S+)/);
      if (group === 'YouTube' && entry && entry[1] === key) return entry[2];
    }
  } catch {
    // No file yet: the default.
  }
  return fallback;
}

// Codecs: auto (default), any, or h264.
const codecSetting = () => youtubeSetting('Codecs', 'auto');

// HomePage: where the remote's Home key goes. Hash routes of the TV app
// (youtube.com/tv#/browse?c=<browse id>).
const HOME_PAGES = {
  subscriptions: '#/browse?c=FEsubscriptions',
  library: '#/browse?c=FEmy_youtube',
  home: '',
};
const homeUrl = () => TV_URL + (HOME_PAGES[youtubeSetting('HomePage', 'subscriptions')] ?? HOME_PAGES.subscriptions);

// HideShorts: true (default) or false; see preload.js.
const hideShorts = () => youtubeSetting('HideShorts', 'true') !== 'false';

// Codecs the GPU decodes, per VA-API: a subset of ['vp9', 'av1'].
function hardwareCodecs() {
  try {
    const out = execFileSync('vainfo', ['--display', 'drm'], { encoding: 'utf8', timeout: 5000, stdio: ['ignore', 'pipe', 'ignore'] });
    const has = profile => new RegExp(`${profile}\\s*:\\s*VAEntrypointVLD`).test(out);
    return [has('VAProfileVP9Profile0') && 'vp9', has('VAProfileAV1Profile0') && 'av1'].filter(Boolean);
  } catch {
    return []; // No VA-API: everything is software, where H.264 is cheapest too.
  }
}

// Codecs to hide from YouTube (see preload.js).
function blockedCodecs() {
  const setting = codecSetting();
  if (setting === 'any') return [];
  if (setting === 'h264') return ['vp9', 'av1'];
  const hardware = hardwareCodecs();
  return ['vp9', 'av1'].filter(codec => !hardware.includes(codec));
}

// Wayland window, hardware video decoding (VA-API), and hardware media keys
// left to the page rather than grabbed by Chromium's MPRIS integration.
app.commandLine.appendSwitch('ozone-platform-hint', 'auto');
app.commandLine.appendSwitch('enable-features', 'AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL');
app.commandLine.appendSwitch('disable-features', 'HardwareMediaKeyHandling,MediaSessionService');
app.userAgentFallback = USER_AGENT;

// Remote keys, as Chromium names them, and what the TV interface wants.
function onKey(win, event, input) {
  if (input.type !== 'keyDown') return;
  if (input.key === 'BrowserBack') {
    // Back would leave the single-page TV app for the previous URL; the TV
    // interface goes back a screen on Escape.
    event.preventDefault();
    win.webContents.sendInputEvent({ type: 'keyDown', keyCode: 'Escape' });
    win.webContents.sendInputEvent({ type: 'keyUp', keyCode: 'Escape' });
  } else if (input.key === 'BrowserHome') {
    event.preventDefault();
    win.loadURL(homeUrl());
  } else if (input.key === 'F11') {
    event.preventDefault();
    win.setFullScreen(!win.isFullScreen());
  }
}

const HIDE_IDLE_CURSOR = `(() => {
  let timer;
  const show = () => {
    document.documentElement.style.cursor = '';
    clearTimeout(timer);
    timer = setTimeout(() => { document.documentElement.style.cursor = 'none'; }, 2000);
  };
  addEventListener('mousemove', show, { passive: true });
  show();
})();`;

function createWindow() {
  const blocked = blockedCodecs();
  console.log(`couchbox-youtube: codecs ${codecSetting()}, hiding [${blocked.join(', ')}]`);
  const win = new BrowserWindow({
    fullscreen: true,
    autoHideMenuBar: true,
    backgroundColor: '#000000',
    title: 'YouTube',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      preload: path.join(__dirname, 'preload.js'),
      additionalArguments: [`--couchbox-block-codecs=${blocked.join(',')}`, `--couchbox-hide-shorts=${hideShorts()}`],
    },
  });
  win.removeMenu();

  const { webContents } = win;
  webContents.on('before-input-event', (event, input) => onKey(win, event, input));
  webContents.on('dom-ready', () => webContents.executeJavaScript(HIDE_IDLE_CURSOR).catch(() => {}));
  // Stay on YouTube: no pop-up windows, and links elsewhere open nowhere.
  webContents.setWindowOpenHandler(() => ({ action: 'deny' }));
  webContents.on('will-navigate', (event, url) => {
    try {
      if (!ALLOWED_HOSTS.test(new URL(url).hostname)) event.preventDefault();
    } catch {
      event.preventDefault();
    }
  });
  win.on('closed', () => app.quit());
  win.loadURL(TV_URL);
}

// Pauses the playing video. Run as `couchbox-youtube --pause` by
// couchbox-focus when YouTube leaves the screen: this app turns off Chromium's
// MPRIS player (see the switches above), so nothing else can pause it.
const PAUSE_VIDEO = `document.querySelectorAll('video').forEach(v => v.pause());`;

// One instance: the tile raises the running window instead of opening a second.
if (!app.requestSingleInstanceLock()) {
  app.quit();
} else if (process.argv.includes('--pause')) {
  // Nothing running to pause: don't start YouTube.
  app.quit();
} else {
  app.on('second-instance', (_event, argv) => {
    const [win] = BrowserWindow.getAllWindows();
    if (!win) return;
    if (argv.includes('--pause')) {
      win.webContents.executeJavaScript(PAUSE_VIDEO).catch(() => {});
      return;
    }
    if (win.isMinimized()) win.restore();
    win.focus();
  });
  app.whenReady().then(() => {
    session.defaultSession.setUserAgent(USER_AGENT);
    // Deny permission prompts the TV interface has no use for (no mouse to
    // answer them), except fullscreen and protected media (Widevine).
    session.defaultSession.setPermissionRequestHandler((_wc, permission, callback) => {
      callback(['fullscreen', 'mediaKeySystem'].includes(permission));
    });
    createWindow();
  });
}
