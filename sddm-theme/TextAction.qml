// Plain-text interactive label for the greeter: no background, no chrome.
// Hover and press are colour + scale only, so the session/account pickers and
// the power actions stay text on the wallpaper.
import QtQuick

Text {
    id: root

    property var pal: null
    property string fontFamily: ""
    property real fontSize: 13
    property bool selected: false

    signal activated()

    readonly property color _idle: root.pal ? root.pal.subtext : "#8a8a99"
    readonly property color _hover: root.pal ? root.pal.text : "#f0f0f5"
    readonly property color _active: root.pal ? root.pal.accent : "#4ecdc4"

    color: root.selected ? _active : (area.containsMouse ? _hover : _idle)
    opacity: area.pressed ? 0.55 : 1.0
    scale: area.pressed ? 0.94 : 1.0
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.weight: 500

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on opacity { NumberAnimation { duration: 80 } }
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    MouseArea {
        id: area
        anchors.fill: parent
        // -5: comfortable target without overlapping the next list row (12 apart).
        anchors.margins: -5
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
