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
    }
}
