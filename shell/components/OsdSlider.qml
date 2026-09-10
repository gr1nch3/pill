// Shared OSD slider used by VolumeState and BrightnessState.
// Displays an icon, animated fill bar, and percent label with mouse-wheel
// support. Emits iconClicked / wheelUp / wheelDown for parent to handle.

import QtQuick

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 10

    property string stateName: ""
    property int value: 0
    property string icon: ""
    property string iconMuted: ""
    property color fillColor: Theme.accent
    property color fillColorMuted: Theme.subtext
    property bool muted: false

    signal iconClicked
    signal wheelUp
    signal wheelDown

    opacity: IslandState.state === stateName ? 1 : 0
    visible: opacity > 0
    focus: visible
    Keys.onEscapePressed: IslandState.closeToIdle()
    Behavior on opacity { NumberAnimation { duration: 150 } }

    MouseArea {
        anchors.fill: parent
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) root.wheelUp()
            else root.wheelDown()
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted && root.iconMuted ? root.iconMuted : root.icon
            font.pixelSize: Theme.font.size.xlarge
            font.family: Theme.font.mono
            color: root.muted ? root.fillColorMuted : root.fillColor
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        Rectangle {
            width: 120
            height: 6
            radius: 3
            color: Theme.background
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: Math.max(6, parent.width * Math.min(root.value / 100, 1))
                height: parent.height
                radius: 3
                color: root.muted ? root.fillColorMuted : root.fillColor
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.value + "%"
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            color: Theme.text
            horizontalAlignment: Text.AlignRight
            width: 36
        }
    }
}
