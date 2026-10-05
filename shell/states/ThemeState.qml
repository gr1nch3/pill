import QtQuick

import "../services"
import "../components"
import "../utils"
import "../eyes"

StatePane {
    id: root
    stateName: "theme"
    pattern: true
    keyboardFocus: true
    preferredWidth: 560
    preferredHeight: root.contentHeight

    anchors.fill: parent

    property real contentHeight: themeCol.implicitHeight + 32

    Column {
        id: themeCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 14

        Row {
            width: parent.width
            anchors.left: parent.left
            spacing: 8

            EyeFace {
                eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
                anchors.verticalCenter: parent.verticalCenter
                baseMood: "active"
            }

            Text {
                id: themeTitle
                text: "Theme"
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        ThemeSelector {
            width: parent.width
            onThemePicked: IslandState.closeToIdle()
        }
    }
}
