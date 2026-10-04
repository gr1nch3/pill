import QtQuick

SurfaceShape {
    id: root
    shape: Theme.shape.style
    slant: Theme.shape.slant

    property string icon: ""
    property bool danger: false
    property bool active: false

    signal clicked
    signal entered
    signal exited

    width: 50
    height: 50
    radius: Theme.shape.radius.tile

    color: {
        if (root.active) return Theme.accent
        if (root.danger) return btn.containsMouse ? Theme.dangerHover : Theme.dangerBg
        return btn.containsMouse ? Theme.surfaceHover : Theme.background
    }

    Behavior on color { ColorAnimation { duration: Theme.motion.normal } }

    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            font.pixelSize: Theme.font.size.xlarge
            font.family: Theme.font.mono
            color: root.active ? Theme.background : (root.danger ? Theme.danger : Theme.text)
        }

    }

    MouseArea {
        id: btn
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onEntered: root.entered()
        onExited: root.exited()
    }
}
