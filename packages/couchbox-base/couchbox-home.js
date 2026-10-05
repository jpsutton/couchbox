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

// Apps that want to know when they are minimized: on Wayland a client isn't
// told, and couchbox-iptv stops its stream while out of sight. By window
// resource class, the D-Bus service to call with Hidden or Shown.
const notifyMinimized = {
    "org.couchbox.iptv": "org.couchbox.iptv",
};

function watchMinimized(w) {
    const service = notifyMinimized[w.resourceClass];
    if (!service) {
        return;
    }
    w.minimizedChanged.connect(function () {
        callDBus(service, "/org/couchbox/iptv", "org.couchbox.iptv.Window", w.minimized ? "Hidden" : "Shown");
    });
}

workspace.windowList().forEach(watchMinimized);
workspace.windowAdded.connect(watchMinimized);

// The app window last in front (not plasmashell, not Bigscreen Settings).
let lastApp = null;

function isApp(w) {
    return w && w.normalWindow && w.resourceClass !== "plasmashell" && w.caption !== "Bigscreen Settings";
}

workspace.windowActivated.connect(function (w) {
    if (isApp(w)) {
        lastApp = w;
    }
});

workspace.windowRemoved.connect(function (w) {
    if (w === lastApp) {
        lastApp = null;
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
