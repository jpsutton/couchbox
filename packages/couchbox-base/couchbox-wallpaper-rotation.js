// couchbox: leave Plasma's default wallpaper ("Next") out of the home-screen
// slideshow, which rotates through /usr/share/wallpapers (couchbox-wallpapers).
// A Plasma update script: plasmashell runs it once per user, including on a
// new user's first login, after the Bigscreen layout is created.
var desks = desktops();
for (var i = 0; i < desks.length; i++) {
    var desk = desks[i];
    desk.currentConfigGroup = ["Wallpaper", "org.kde.slideshow", "General"];
    desk.writeConfig("UncheckedSlides", ["/usr/share/wallpapers/Next/", "/usr/share/wallpapers/Next"]);
}
