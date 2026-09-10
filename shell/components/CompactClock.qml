// Self-updating HH:MM AM/PM clock with blinking colon.
// Used in IdleState (collapsed + expanded) and LockscreenState compact pill.
// Each instance runs its own 1-second timer independent of parent.

import QtQuick

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

    readonly property string _hours: { var h = new Date().getHours(); return (h % 12) || 12 }
    readonly property string _minutes: Qt.formatTime(new Date(), "mm")
    readonly property string _ampm: Qt.formatTime(new Date(), "AP")

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
            running: root.active; loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 700 }
            NumberAnimation { to: 1.0; duration: 700 }
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
        color: root.ampmColor
        font.pixelSize: root.ampmFontSize
        font.family: Theme.font.family
        text: root._ampm
        anchors.verticalCenter: parent.verticalCenter
        anchors.bottom: minutesText.bottom
        anchors.bottomMargin: root.ampmBottomMargin
    }

    Timer {
        interval: 1000; running: root.active; repeat: true
        onTriggered: {
            var now = new Date()
            var h = (now.getHours() % 12) || 12
            hoursText.text = h
            minutesText.text = Qt.formatTime(now, "mm")
            ampmText.text = Qt.formatTime(now, "AP")
        }
    }
}
