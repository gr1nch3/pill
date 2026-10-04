import QtQuick

// Standard description block under a settings section.
Text {
    width: parent.width
    color: Theme.subtext
    font.pixelSize: Theme.font.size.small
    font.family: Theme.font.family
    wrapMode: Text.WordWrap
    visible: text !== ""
}
