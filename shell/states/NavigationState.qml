import QtQuick
import Quickshell
import Quickshell.Hyprland // ponytail: hypr-only workspace OSD; inert elsewhere

import "../services"
import "../components"

Item {
    id: root
    x: 16; y: 5

    opacity: IslandState.state === "navigation" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 100 } }

    property int activeId: 1
    property var displayIds: [1, 2, 3, 4, 5]
    property var occupiedMap: ({})

    readonly property real pillWidth: Math.max(160, navRow.width + 32)
    readonly property real pillHeight: navRow.height + 10

    function refresh() {
        var ws = Hyprland.focusedWorkspace
        root.activeId = ws ? ws.id : 1

        var map = {}
        var ids = [1, 2, 3, 4, 5]
        var vals = Hyprland.workspaces ? Hyprland.workspaces.values : null
        if (vals) {
            var len = vals.length
            for (var i = 0; i < len; i++) {
                var w = vals[i]
                var winCount = w.lastIpcObject ? w.lastIpcObject.windows || 0 : 0
                map[w.id] = winCount > 0
                if (w.id > 5 && (winCount > 0 || w.id === root.activeId)) {
                    if (ids.indexOf(w.id) === -1) ids.push(w.id)
                }
            }
        }
        ids.sort(function(a, b) { return a - b })
        root.displayIds = ids
        root.occupiedMap = map
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.refresh() }
    }

    Component.onCompleted: root.refresh()

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

                width: 32; height: 32; radius: 8
                color: isActive ? Theme.accent : (isOccupied ? Theme.highlight : "transparent")
                border.width: isActive ? 0 : 1
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
