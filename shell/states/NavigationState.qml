import QtQuick

import "../services"
import "../components"

StatePane {
    id: root
    stateName: "navigation"
    fadeDuration: 100
    preferredWidth: Math.max(160, navRow.width + 32)
    preferredHeight: navRow.height + 10

    x: 16; y: 5

    readonly property int activeId: Workspaces.activeId
    readonly property var displayIds: Workspaces.displayIds
    readonly property var occupiedMap: Workspaces.occupiedMap

    Row {
        id: navRow
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 6

        Repeater {
            model: root.displayIds
            delegate: Rectangle {
                id: wsDot
                required property var modelData
                property int wsId: modelData
                property bool isActive: wsId === root.activeId
                property bool isOccupied: root.occupiedMap[wsId] || false

                width: 32; height: 32; radius: Theme.shape.radius.control
                color: isActive ? Theme.accent : (isOccupied ? Theme.highlight : "transparent")
                border.width: isActive ? 0 : Theme.shape.border.width
                border.color: isOccupied ? Theme.border : Qt.rgba(1, 1, 1, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: wsId.toString()
                    color: isActive ? Theme.background : (isOccupied ? Theme.text : Theme.subtext)
                    font.pixelSize: Theme.font.size.normal
                    font.family: Theme.font.family
                    font.weight: isActive ? 700 : 500
                }
            }
        }
    }
}
