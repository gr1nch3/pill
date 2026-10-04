import QtQuick

Text {
    id: root

    signal clicked

    text: "󰁍"
    color: backHover.containsMouse ? Theme.text : Theme.subtext
    font.pixelSize: Theme.font.size.large
    font.family: Theme.font.mono
    Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

    MouseArea {
        id: backHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
