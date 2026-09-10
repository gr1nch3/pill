import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

import "../services"
import "../components"
import "../eyes"

Column {
    anchors.fill: parent; anchors.margins: 16
    spacing: 12

    opacity: IslandState.state === "launcher" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    onVisibleChanged: {
        if (visible) { searchInput.text = ""; searchInput.forceActiveFocus() }
    }

    Rectangle {
        width: parent.width; height: 42; radius: 12; color: Theme.background

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: "󰍉"
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.mono
                color: Theme.subtext
                anchors.verticalCenter: parent.verticalCenter
            }

            TextInput {
                id: searchInput
                focus: true
                anchors.verticalCenter: parent.verticalCenter
                x: 26
                width: parent.width - 26
                color: Theme.text; font.pixelSize: Theme.font.size.normal; font.family: Theme.font.family; clip: true

                Text {
                    anchors.fill: parent; text: "Search..."; color: Theme.subtext
                    font.pixelSize: Theme.font.size.normal; font.family: Theme.font.family
                    visible: searchInput.text.length === 0
                }

                Keys.onEscapePressed: IslandState.closeToIdle()
                Keys.onPressed: function(event) {
                    const ctrl = event.modifiers & Qt.ControlModifier
                    if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && ctrl)) {
                        if (appList.currentIndex > 0) appList.currentIndex--
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && ctrl)) {
                        if (appList.currentIndex < appList.count - 1) appList.currentIndex++
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        var item = appList.currentItem
                        if (item && item.entry) { item.entry.execute(); IslandState.closeToIdle() }
                        event.accepted = true
                    }
                    if (event.accepted) appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
                }
            }

            Eye {
                eyeWidth: 16; eyeHeight: 12; eyeSpacing: 6
                anchors.verticalCenter: parent.verticalCenter
                moods: Theme.eyeMoods
                mood: searchInput.text !== "" ? "active" : "idle"
            }
        }
    }

    ListView {
        id: appList
        width: parent.width; height: parent.height - 42 - 12
        clip: true; currentIndex: 0
        Keys.onEscapePressed: IslandState.closeToIdle()
        focus: true

        model: ScriptModel {
            values: {
                const all = [...DesktopEntries.applications.values]
                const q = searchInput.text.trim().toLowerCase()
                return q === "" ? all : all.filter(d => (d.name && d.name.toLowerCase().includes(q)) || (d.comment && d.comment.toLowerCase().includes(q)))
            }
        }

        highlight: Rectangle { radius: 10; color: Theme.highlight }
        highlightMoveDuration: 100

        delegate: Item {
            id: delegateItem
            required property var modelData
            required property int index
            property var entry: modelData
            width: appList.width; height: 52

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: appList.currentIndex = delegateItem.index
                onClicked: { delegateItem.entry.execute(); IslandState.closeToIdle() }
            }

            Row {
                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 12
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    source: Quickshell.iconPath(modelData.icon, true)
                    width: 26; height: 26
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 38
                    spacing: 2

                    Text {
                        anchors.left: parent.left
                        color: Theme.text; font.pixelSize: Theme.font.size.normal; font.family: Theme.font.family
                        font.weight: 500
                        text: modelData.name ?? ""; elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        anchors.left: parent.left
                        color: Theme.subtext; font.pixelSize: Theme.font.size.small; font.family: Theme.font.family
                        text: modelData.comment ?? modelData.genericName ?? ""
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }
        }
    }
}
