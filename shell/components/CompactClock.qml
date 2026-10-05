// Self-updating HH:MM AM/PM clock with blinking colon.
// Used in IdleState (collapsed + expanded) and LockscreenState compact pill.
// Each instance runs its own 1-second timer independent of parent.

import QtQuick

import "../services"

Row {
    id: root

    property int fontSize: Theme.font.size.large
    property int ampmFontSize: Theme.font.size.caption
    property int fontWeight: 600
    property int ampmBottomMargin: 1
    property color textColor: Theme.text
    property color ampmColor: Theme.subtext

    // False pauses the clock timer and colon blink (hidden bar).
    property bool active: true

    spacing: 1

    // One ticker drives the whole clock (time + dateText).
    property date now: new Date()
    readonly property bool format24h: Config.clockFormat === "24"
    readonly property string _hours: {
        var h = root.now.getHours();
        if (format24h)
            return (h < 10 ? "0" : "") + h;
        return (h % 12) || 12;
    }
    readonly property string _minutes: Qt.formatTime(root.now, "mm")
    readonly property string _ampm: Qt.formatTime(root.now, "AP")
    readonly property string dateText: Qt.formatDate(root.now, "ddd, MMM d")

    Text {
        id: hoursText
        color: root.textColor
        font.pixelSize: root.fontSize
        font.family: Theme.font.family
        font.weight: root.fontWeight
        text: root._hours
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        color: root.textColor
        font.pixelSize: root.fontSize
        font.family: Theme.font.family
        font.weight: root.fontWeight
        text: ":"
        anchors.verticalCenter: parent.verticalCenter
        SequentialAnimation on opacity {
            running: root.active
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.25
                duration: 700
            }
            NumberAnimation {
                to: 1.0
                duration: 700
            }
        }
    }

    Text {
        id: minutesText
        color: root.textColor
        font.pixelSize: root.fontSize
        font.family: Theme.font.family
        font.weight: root.fontWeight
        text: root._minutes
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: ampmText
        visible: !root.format24h
        color: root.ampmColor
        font.pixelSize: root.ampmFontSize
        font.family: Theme.font.family
        text: root._ampm
        anchors.verticalCenter: parent.verticalCenter
        anchors.bottom: minutesText.bottom
        anchors.bottomMargin: root.ampmBottomMargin
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: root.now = new Date()
    }
}
