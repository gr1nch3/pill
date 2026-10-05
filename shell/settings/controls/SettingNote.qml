import QtQuick
import "../../components"

// Standard description/status block under a settings section. `tone` picks
// the ink: muted copy, a failure, or a success confirmation.
Text {
    property string tone: "muted"   // muted | danger | success

    width: parent.width
    topPadding: 2
    bottomPadding: 2
    color: tone === "danger" ? Theme.danger : (tone === "success" ? Theme.accent : Theme.subtext)
    font.pixelSize: Theme.font.size.small
    font.family: Theme.font.family
    wrapMode: Text.WordWrap
    visible: text !== ""
}
