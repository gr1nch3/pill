import QtQuick

SurfaceShape {
    id: root
    shape: Theme.shape.style
    slant: Theme.shape.slant

    property string icon
    property string label
    property color iconColor: Theme.text
    property int labelWeight: 600
    property int cellRadius: 16

    signal clicked

    radius: cellRadius
    color: tileHover.containsMouse ? Theme.surfaceHover : Theme.background
    Behavior on color {
        ColorAnimation {
            duration: Theme.motion.normal
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            font.pixelSize: Theme.font.size.xlarge
            font.family: Theme.font.mono
            color: root.iconColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            font.weight: root.labelWeight
            color: Theme.text
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: tileHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
