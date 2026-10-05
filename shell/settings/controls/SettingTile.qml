import QtQuick

import "../../components"

// Compact card for actions and toggles that read better in a row than a
// full-width settings row. `toggle` turns the whole tile into a switch; the
// click always flips/act. `active` is the on state (and the accent treatment).
Rectangle {
    id: tile

    property string icon: ""
    property string title: ""
    property string hint: ""
    property bool active: false
    property bool toggle: false
    property bool danger: false
    signal clicked()
    signal toggled(bool value)

    height: 86
    radius: Theme.shape.radius.card
    color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
        : (tileMouse.containsMouse ? Theme.surfaceHover : Theme.surface)
    border.width: active ? Theme.shape.border.emphasis : Theme.shape.border.width
    border.color: danger && tileMouse.containsMouse ? Theme.danger
        : (active ? Theme.accent : Theme.border)
    scale: tileMouse.containsMouse ? 1.02 : 1

    Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
    Behavior on border.color { ColorAnimation { duration: Theme.motion.hover } }
    Behavior on border.width { NumberAnimation { duration: Theme.motion.hover } }
    Behavior on scale { NumberAnimation { duration: Theme.motion.normal; easing.type: Easing.OutCubic } }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.icon
            color: active ? Theme.accent : (tile.danger && tileMouse.containsMouse ? Theme.danger : Theme.text)
            font.pixelSize: 26
            font.family: Theme.font.mono
            Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.title
            color: Theme.text
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family
            font.weight: tile.active ? 700 : 500
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: tile.hint !== ""
            text: tile.hint
            color: Theme.subtext
            font.pixelSize: Theme.font.size.caption
            font.family: Theme.font.family
        }
    }

    // switch indicator for toggle tiles
    Rectangle {
        visible: tile.toggle
        anchors { right: parent.right; top: parent.top; margins: 9 }
        width: 30; height: 16; radius: 8
        color: tile.active ? Theme.accent : Theme.highlight
        Behavior on color { ColorAnimation { duration: Theme.motion.normal } }

        Rectangle {
            width: 12; height: 12; radius: 6
            y: 2
            x: tile.active ? parent.width - width - 2 : 2
            color: tile.active ? Theme.background : Theme.subtext
            Behavior on x { NumberAnimation { duration: Theme.motion.normal; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (tile.toggle) tile.toggled(!tile.active)
            else tile.clicked()
        }
    }
}
