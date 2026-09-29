// Home on the remote (KEY_HOMEPAGE) goes to the Bigscreen home screen.
//
// Bigscreen 6.7.5 is meant to bind this key itself, but its shortcuts never
// get registered with kglobalaccel, so Home does nothing. Register it here:
// minimize every app window, as Bigscreen's own handler would. Bigscreen
// Settings is closed instead of minimized, because its focus can get stuck
// after a sub-page closes, leaving no key that works inside it.
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

registerShortcut("couchbox-home", "couchbox: go to the home screen", "Home Page", goHome);
