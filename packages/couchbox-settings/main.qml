// SPDX-License-Identifier: MIT
// couchbox page in Bigscreen Settings (installed as ui/main.qml in the KCM). Each setting names its couchboxrc group,
// key and default; the apps read the same keys.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.bigscreen as Bigscreen

Bigscreen.ScrollablePage {
    id: root

    title: "couchbox"
    background: null

    leftPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    rightPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

    onActiveFocusChanged: {
        if (activeFocus) {
            youtubeCodecs.forceActiveFocus();
        }
    }

    ColumnLayout {
        // ScrollablePage's scroll view eats the Left key; hand it back so Left
        // returns to the settings sidebar.
        KeyNavigation.left: root.KeyNavigation.left
        spacing: 0

        // Up and Down move between the settings. Without these links the keys
        // fall through to the scroll view, which scrolls the page instead.
        // Set here because the Repeater's delegates only exist once it has run.
        Component.onCompleted: {
            const chain = [youtubeCodecs, youtubeHome, youtubeShorts, plezyScaling];
            for (let i = 0; i < transcode.count; i++) {
                chain.push(transcode.itemAt(i));
            }
            chain.push(detectHardware, automaticTimeZone, keepMusic);
            for (let i = 0; i + 1 < chain.length; i++) {
                chain[i].KeyNavigation.down = chain[i + 1];
                chain[i + 1].KeyNavigation.up = chain[i];
            }
        }

        QQC2.Label {
            text: "YouTube"
            font.pixelSize: Bigscreen.Units.headingFontPixelSize

            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
        }

        // [YouTube] Codecs in couchboxrc, read by couchbox-youtube at start.
        Bigscreen.ComboBoxDelegate {
            id: youtubeCodecs
            Layout.bottomMargin: Kirigami.Units.smallSpacing

            readonly property string group: "YouTube"
            readonly property string key: "Codecs"
            readonly property string fallback: "auto"

            // The delegate's second line shows the current choice; the
            // explanation goes in the label below.
            text: "Video codecs"
            textRole: "text"
            valueRole: "value"
            model: [
                { text: "Automatic", value: "auto" },
                { text: "Any codec", value: "any" },
                { text: "H.264 only", value: "h264" },
            ]

            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(kcm.value(group, key, fallback)))
            onActivated: index => kcm.setValue(group, key, model[index].value)
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Automatic plays only the formats this PC's graphics can decode; H.264 only suits "
                + "older PCs. Takes effect the next time YouTube starts."
        }

        // [YouTube] HomePage: where couchbox-youtube starts and Home goes.
        Bigscreen.ComboBoxDelegate {
            id: youtubeHome
            Layout.bottomMargin: Kirigami.Units.smallSpacing

            readonly property string group: "YouTube"
            readonly property string key: "HomePage"
            readonly property string fallback: "subscriptions"

            text: "Start page and Home button"
            textRole: "text"
            valueRole: "value"
            model: [
                { text: "Subscriptions", value: "subscriptions" },
                { text: "Home", value: "home" },
                { text: "Library", value: "library" },
            ]

            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(kcm.value(group, key, fallback)))
            onActivated: index => kcm.setValue(group, key, model[index].value)
        }

        // [YouTube] HideShorts, read by couchbox-youtube at start.
        Bigscreen.SwitchDelegate {
            id: youtubeShorts
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.gridUnit

            text: "Hide Shorts"
            description: "Takes effect the next time YouTube starts"

            Component.onCompleted: checked = kcm.value("YouTube", "HideShorts", "true") !== "false"
            onToggled: kcm.setValue("YouTube", "HideShorts", checked ? "true" : "false")
        }

        QQC2.Label {
            text: "Video playback"
            font.pixelSize: Bigscreen.Units.headingFontPixelSize

            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
        }

        // [Video] in couchboxrc. couchbox-video-profile picks these once, at
        // the first login, from what the graphics hardware decodes; changing one
        // here writes it into Plezy and Kodi (kcm.applyVideo), and nothing
        // resets it later except "Detect hardware again".
        QQC2.Label {
            id: hardware
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
            wrapMode: Text.WordWrap
            opacity: 0.7

            function refresh() {
                const decodes = kcm.value("Hardware", "Decodes", "");
                const lowPower = kcm.value("Hardware", "LowPower", "false") === "true";
                text = decodes === ""
                    ? "Hardware not detected yet."
                    : "This PC's graphics decode: " + decodes + "."
                        + (lowPower ? " It counts as low-power, so the settings below start out lighter." : "");
            }
            Component.onCompleted: refresh()
        }

        Bigscreen.ComboBoxDelegate {
            id: plezyScaling
            Layout.bottomMargin: Kirigami.Units.smallSpacing

            readonly property string group: "Video"
            readonly property string key: "PlezyScaling"
            readonly property string fallback: "quality"

            text: "Plezy picture scaling"
            textRole: "text"
            valueRole: "value"
            model: [
                { text: "Best quality", value: "quality" },
                { text: "Fast", value: "fast" },
            ]

            function refresh() { currentIndex = Math.max(0, indexOfValue(kcm.value(group, key, fallback))) }
            Component.onCompleted: refresh()
            onActivated: index => {
                kcm.setValue(group, key, model[index].value);
                kcm.applyVideo();
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Fast uses simpler scaling, so low-power graphics don't drop frames. On a 1080p TV "
                + "playing 1080p video it looks the same."
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            wrapMode: Text.WordWrap
            text: "Ask the server to convert"
        }

        Repeater {
            id: transcode
            model: [
                { key: "TranscodeHEVC", text: "HEVC (H.265)", note: "Plezy and Kodi" },
                { key: "TranscodeHEVC10", text: "HEVC 10-bit", note: "Jellyfin for Kodi only" },
                { key: "TranscodeAV1", text: "AV1", note: "Plezy and Kodi" },
                { key: "TranscodeVP9", text: "VP9", note: "Jellyfin for Kodi only" },
            ]

            delegate: Bigscreen.SwitchDelegate {
                required property var modelData
                Layout.fillWidth: true
                Layout.bottomMargin: Kirigami.Units.smallSpacing

                text: modelData.text
                description: modelData.note

                function refresh() { checked = kcm.value("Video", modelData.key, "false") === "true" }
                Component.onCompleted: refresh()
                onToggled: {
                    kcm.setValue("Video", modelData.key, checked ? "true" : "false");
                    kcm.applyVideo();
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "For formats this PC can't play smoothly: the server converts them while you watch. "
                + "Changes take effect the next time Plezy or Kodi starts."
        }

        Bigscreen.ButtonDelegate {
            id: detectHardware
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.gridUnit

            text: "Detect hardware again"
            description: "Resets the video playback settings to what suits this PC"

            onClicked: {
                kcm.probeVideo();
                hardware.refresh();
                plezyScaling.refresh();
                for (let i = 0; i < transcode.count; i++) {
                    transcode.itemAt(i).refresh();
                }
            }
        }

        QQC2.Label {
            text: "Time"
            font.pixelSize: Bigscreen.Units.headingFontPixelSize

            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
        }

        // [Time] Automatic in couchboxrc, read by couchbox-timezone at login.
        // A zone set by hand elsewhere switches it off (couchbox-timezone).
        Bigscreen.SwitchDelegate {
            id: automaticTimeZone
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing

            property string status: ""

            text: "Set the time zone automatically"
            description: kcm.timeZone() + status

            Component.onCompleted: checked = kcm.value("Time", "Automatic", "true") !== "false"
            onToggled: {
                kcm.setValue("Time", "Automatic", checked ? "true" : "false");
                status = checked && !kcm.updateTimeZone() ? " (offline: updates once online)" : "";
                // timeZone() isn't a property; re-evaluate the binding.
                description = Qt.binding(() => kcm.timeZone() + status);
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Finds the time zone from this network's location (ipinfo.io) each time couchbox starts. "
                + "To pick one yourself, use Timezone under System, Adjust date and time; "
                + "that switches this off."
        }

        QQC2.Label {
            text: "Apps in the background"
            font.pixelSize: Bigscreen.Units.headingFontPixelSize

            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
        }

        // [Playback] KeepMusicPlaying in couchboxrc, read by couchbox-focus
        // each time an app leaves the screen.
        Bigscreen.SwitchDelegate {
            id: keepMusic
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing

            text: "Keep music playing"
            description: "When you go to the home screen or another app"

            Component.onCompleted: checked = kcm.value("Playback", "KeepMusicPlaying", "true") !== "false"
            onToggled: kcm.setValue("Playback", "KeepMusicPlaying", checked ? "true" : "false")
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Video pauses when its app leaves the screen (live TV stops), in Plezy, Kodi, YouTube "
                + "and Internet TV; press Play when you come back."
        }
    }
}
