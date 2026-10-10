import QtQuick
import "../../components"

// Standard description/status block under a settings section. `tone` picks
// the ink: muted copy, a failure, a warning, or a success confirmation.
Text {
    property string tone: "muted"   // muted | danger | warning | success

    width: parent.width
    topPadding: 2
    bottomPadding: 2
    color: Theme.statusColor(tone)
    font.pixelSize: Theme.font.size.small
    font.family: Theme.font.family
    wrapMode: Text.WordWrap
    visible: text !== ""
}
