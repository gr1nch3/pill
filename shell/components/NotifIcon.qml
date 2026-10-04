import QtQuick
import Quickshell

Rectangle {
    id: root

    property string appIcon: ""
    property string appName: ""
    property int urgency: 0
    property bool useUrgencyColor: true
    property real iconSize: 36
    property real iconRadius: 10

    width: iconSize
    height: iconSize
    radius: iconRadius
    color: useUrgencyColor && urgency === 2 ? Theme.dangerBg : Theme.background
    clip: true

    Image {
        id: notifImg
        anchors.fill: parent
        anchors.margins: Math.max(2, parent.width * 0.1)
        source: Quickshell.iconPath(root.appIcon)
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        text: (root.appName || "?").charAt(0).toUpperCase()
        font.pixelSize: Math.round(parent.width * 0.45)
        font.family: Theme.font.family
        font.bold: true
        color: Theme.accent
        visible: notifImg.status !== Image.Ready
    }
}
