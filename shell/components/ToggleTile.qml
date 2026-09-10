import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool iconButton: true
    property bool btnActive: false
    property bool tileActive: false

    signal iconClicked
    signal clicked

    height: 64
    radius: 16
    color: root.tileActive ? Theme.accent : Theme.background
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        id: bodyHover
        anchors.fill: parent
        radius: root.radius
        color: bodyArea.containsMouse
            ? (root.tileActive ? Qt.lighter(Theme.accent, 1.08) : Theme.surfaceHover)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        id: iconBtn
        x: root.iconButton ? 8 : 12
        y: root.iconButton ? (parent.height - height) / 2 : 0
        width: root.iconButton ? 40 : 22
        height: root.iconButton ? 40 : parent.height
        radius: root.iconButton ? 12 : 0
        color: root.iconButton
            ? (iconArea.containsMouse
                ? (root.btnActive ? Qt.lighter(Theme.accent, 1.08) : Theme.surfaceHover)
                : (root.btnActive ? Qt.lighter(Theme.accent, 1.08) : Theme.surfaceHover ))
            : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
        border.width: root.iconButton && !root.btnActive ? 1 : 0
        border.color: Theme.border

        Text {
            text: root.icon
            font.pixelSize: Theme.font.size.xlarge
            font.family: Theme.font.mono
            color: root.btnActive ? Theme.background : root.tileActive ? Theme.background : Theme.text
            x: root.iconButton ? (parent.width - implicitWidth) / 2 : 0
            y: (parent.height - implicitHeight) / 2
        }

        MouseArea {
            id: iconArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: iconBtn.right
        anchors.right: parent.right
        anchors.leftMargin: root.iconButton ? 10 : 0
        anchors.rightMargin: 12
        spacing: 2

        Text {
            text: root.title
            color: root.tileActive ? Theme.background : Theme.text
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            font.weight: 600
            width: parent.width
            elide: Text.ElideRight
        }

        Text {
            text: root.subtitle
            color: root.tileActive ? Theme.background : Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            width: parent.width
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: bodyArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: root.iconButton ? iconBtn.right : parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.iconButton ? 10 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
