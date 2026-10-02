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
    }
}
