// Meta+Home Page toggles between the apps and the Bigscreen home screen.
//
// A long press of the remote's Home key sends Meta+Home Page (fire-blaster's
// [hold] action, /etc/fire-blaster/config.toml); a short press reaches the
// app in front, so Kodi and Plezy can use Home for their own home screen.
// Plain Home Page is deliberately not bound here: a global shortcut would
// take it from every app.
//
// From an app: go to the home screen. Bigscreen 6.7.5 means to bind Home
// itself, but its shortcuts never get registered with kglobalaccel (see
// UPSTREAM-BUGS 24). This does what its handler would: minimize every app
// window. Bigscreen Settings is closed instead of minimized, because its focus
// can get stuck after a sub-page closes, leaving no key that works inside it.
//
// From the home screen, with no Bigscreen overlay or sidebar open: bring back
// the app that was last in front, if it is still running.

// The app window last in front (not plasmashell, not Bigscreen Settings).
let lastApp = null;

function isApp(w) {
    return w && w.normalWindow && w.resourceClass !== "plasmashell" && w.caption !== "Bigscreen Settings";
}

// couchbox-focus pauses (or, for live TV, stops) an app that leaves the
// screen: minimized (long Home), or another app brought to the front.
// Bigscreen's own overlays don't count. On Wayland an app isn't told it was
// minimized, so it can't do this itself.
const backgrounded = [];

function focusCall(method, w) {
    callDBus("org.couchbox.Focus", "/org/couchbox/Focus", "org.couchbox.Focus", method, w.resourceClass, w.pid);
}

function background(w) {
    if (!isApp(w) || backgrounded.includes(w)) {
        return;
    }
    backgrounded.push(w);
    focusCall("Background", w);
}

function foreground(w) {
    const i = backgrounded.indexOf(w);
    if (i < 0) {
        return;
    }
    backgrounded.splice(i, 1);
    focusCall("Foreground", w);
}

function watch(w) {
    if (!isApp(w)) {
        return;
    }
    w.minimizedChanged.connect(function () {
        if (w.minimized) {
            background(w);
        } else {
            foreground(w);
        }
    });
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);

workspace.windowActivated.connect(function (w) {
    if (!isApp(w)) {
        return;
    }
    if (lastApp && lastApp !== w && !lastApp.minimized) {
        background(lastApp);
    }
    foreground(w);
    lastApp = w;
});

workspace.windowRemoved.connect(function (w) {
    if (w === lastApp) {
        lastApp = null;
    }
    const i = backgrounded.indexOf(w);
    if (i >= 0) {
        backgrounded.splice(i, 1);
    }
});

// An app window (or Bigscreen Settings) on screen.
function appShowing() {
    for (const w of workspace.windowList()) {
        if (w.normalWindow && w.resourceClass !== "plasmashell" && !w.minimized) {
            return true;
        }
    }
    return false;
}

// A Bigscreen overlay or sidebar open over the home screen: any plasmashell
// window besides the desktop itself and panels.
function overlayShowing() {
    for (const w of workspace.windowList()) {
        if (w.resourceClass === "plasmashell" && !w.desktopWindow && !w.dock && !w.minimized && w.onCurrentDesktop) {
            return true;
        }
    }
    return false;
}

function goHome() {
    for (const w of workspace.windowList()) {
        if (!w.normalWindow || w.resourceClass === "plasmashell") {
            continue;
        }
        if (w.caption === "Bigscreen Settings") {
            w.closeWindow();
        } else if (w.minimizable && !w.minimized) {
            w.minimized = true;
        }
    }
}

function homeOrBack() {
    if (!appShowing() && !overlayShowing() && lastApp && workspace.windowList().includes(lastApp)) {
        lastApp.minimized = false;
        workspace.activeWindow = lastApp;
        return;
    }
    goHome();
}

// A new action ID, not "couchbox-home": kglobalaccel keeps a saved key for an
// existing ID over a changed default, and that ID was bound to plain Home Page.
registerShortcut("couchbox-home-hold", "couchbox: go to the home screen, or back to the last app (hold Home)", "Meta+Home Page", homeOrBack);
