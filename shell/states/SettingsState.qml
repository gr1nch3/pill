// Thin state wrapper: the actual settings workspace lives in shell/settings/.
// IslandPill reads the pane size from here.
import QtQuick

import "../components"
import "../settings"

StatePane {
    id: root
    stateName: "settings"
    centered: true
    keyboardFocus: true
    preferredWidth: window.panelWidth
    preferredHeight: window.contentHeight

    anchors.fill: parent

    SettingsWindow {
        id: window
        anchors.fill: parent
    }
}
