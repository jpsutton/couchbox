// Meta+Home Page goes to the Bigscreen home screen.
//
// A long press of the remote's Home key sends Meta+Home Page (fire-blaster's
// [hold] action, /etc/fire-blaster/config.toml); a short press reaches the
// app in front, so Kodi and Plezy can use Home for their own home screen.
// Plain Home Page is deliberately not bound here: a global shortcut would
// take it from every app.
//
// Bigscreen 6.7.5 means to bind Home itself, but its shortcuts never get
// registered with kglobalaccel. This does what its handler would: minimize
// every app window. Bigscreen Settings is closed instead of minimized,
// because its focus can get stuck after a sub-page closes, leaving no key
// that works inside it.
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

// A new action ID, not "couchbox-home": kglobalaccel keeps a saved key for an
// existing ID over a changed default, and that ID was bound to plain Home Page.
registerShortcut("couchbox-home-hold", "couchbox: go to the home screen (hold Home)", "Meta+Home Page", goHome);
