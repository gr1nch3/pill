import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    property string source: ""
    property string placeholderIcon: "󰝚"
    property int placeholderSize: 24

    color: Theme.surfaceHover
    clip: true

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 256
        sourceSize.height: 256
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        maskSource: mask
        maskEnabled: true
        visible: img.status === Image.Ready && root.source !== ""
    }

    Text {
        anchors.centerIn: parent
        text: root.placeholderIcon
        font.pixelSize: root.placeholderSize
        font.family: Theme.font.mono
        color: Theme.accent
        visible: img.status !== Image.Ready || root.source === ""
    }
}
