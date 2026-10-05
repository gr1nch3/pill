// Stats card used by ControlCenterState for CPU / RAM / Disk.
// Displays icon, percent value, and animated sparkline bar.
// Accepts iconColor, accentColor, and dangerThreshold for per-metric styling.

import QtQuick

SurfaceShape {
    id: root
    shape: Theme.shape.style
    slant: Theme.shape.slant

    property string cardIcon: ""
    property color iconColor: Theme.accent
    property int cardValue: 0
    property color accentColor: Theme.accent
    property int dangerThreshold: 80

    width: (parent.width - 12) / 3
    height: parent.height
    radius: Theme.shape.radius.card
    color: Theme.background

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.cardIcon
            font.pixelSize: Theme.font.size.large
            font.family: Theme.font.mono
            color: root.iconColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.cardValue + "%"
            color: Theme.text
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family
            font.weight: 600
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 4
            radius: 2
            color: Theme.surfaceHover

            Rectangle {
                width: parent.width * Math.min(1, root.cardValue / 100)
                height: parent.height
                radius: 2
                color: root.cardValue > root.dangerThreshold ? Theme.danger : root.accentColor
                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }
    }
}
