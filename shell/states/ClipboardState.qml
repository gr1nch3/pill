import QtQuick
import QtQuick.Controls
import Quickshell.Io

import "../services"
import "../components"
import "../utils"
import "../eyes"

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 16

    opacity: IslandState.state === "clipboard" ? 1 : 0
    visible: opacity > 0
    focus: visible
    Behavior on opacity { NumberAnimation { duration: 150 } }

    property var items: []
    property var buffer: []
    property string filterText: ""
    property int currentIndex: 0

    readonly property var filteredItems: {
        var all = root.items
        if (root.filterText === "") return all
        var f = root.filterText.toLowerCase()
        var result = []
        for (var i = 0; i < all.length; i++) {
            if (all[i].text.toLowerCase().indexOf(f) !== -1) result.push(all[i])
        }
        return result
    }

    function load() {
        root.buffer = []
        root.items = []
        root.currentIndex = 0
        listProc.running = true
    }

    function copyCurrent() {
        var item = root.filteredItems[root.currentIndex]
        if (item) {
            copyProc.command = ["sh", "-c", "cliphist decode " + item.id + " | wl-copy"]
            copyProc.running = true
            IslandState.closeToIdle()
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            load()
            searchField.forceActiveFocus()
        }
    }

    Keys.onEscapePressed: IslandState.closeToIdle()
    Keys.onPressed: function(event) {
        var ctrl = event.modifiers & Qt.ControlModifier
        if ((event.key === Qt.Key_N && ctrl) || (event.key === Qt.Key_J && ctrl)) {
            event.accepted = true
            if (root.currentIndex < root.filteredItems.length - 1) {
                root.currentIndex++
                clipList.positionViewAtIndex(root.currentIndex, ListView.Contain)
            }
        } else if ((event.key === Qt.Key_P && ctrl) || (event.key === Qt.Key_K && ctrl)) {
            event.accepted = true
            if (root.currentIndex > 0) {
                root.currentIndex--
                clipList.positionViewAtIndex(root.currentIndex, ListView.Contain)
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true
            copyCurrent()
        } else if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (root.currentIndex < root.filteredItems.length - 1) {
                root.currentIndex++
                clipList.positionViewAtIndex(root.currentIndex, ListView.Contain)
            }
        } else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (root.currentIndex > 0) {
                root.currentIndex--
                clipList.positionViewAtIndex(root.currentIndex, ListView.Contain)
            }
        }
    }

    Process {
        id: listProc
        command: ["sh", "-c", "cliphist list | head -100"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = line.trim()
                if (trimmed === "") return
                var idx = trimmed.indexOf("\t")
                if (idx < 0) return
                var entry = {
                    id: trimmed.substring(0, idx),
                    text: trimmed.substring(idx + 1)
                }
                root.buffer.push(entry)
            }
        }
        onExited: {
            root.items = root.buffer.slice()
            if (root.items.length > 0 && root.currentIndex >= root.items.length) {
                root.currentIndex = root.items.length - 1
            }
        }
    }

    Process { id: copyProc; command: []; running: false }

    Column {
        anchors.fill: parent
        spacing: 8

        Row {
            width: parent.width
            spacing: 10

            Eye {
                eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
                anchors.verticalCenter: parent.verticalCenter
                moods: Theme.eyeMoods
                mood: filterText !== "" ? "active" : "idle"
            }

            Text {
                text: "Clipboard History"
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        TextField {
            id: searchField
            width: parent.width
            height: 32
            focus: true
            placeholderText: "Search clipboard..."
            placeholderTextColor: Theme.subtext
            color: Theme.text
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            leftPadding: 10
            rightPadding: 10
            verticalAlignment: TextInput.AlignVCenter
            Keys.forwardTo: [root]
            background: Rectangle {
                radius: 8
                color: Theme.background
            }
            onTextChanged: {
                root.filterText = searchField.text
                root.currentIndex = 0
                clipList.positionViewAtIndex(0, ListView.Beginning)
            }
            onAccepted: copyCurrent()
            Keys.onEscapePressed: {
                if (searchField.text !== "") {
                    searchField.text = ""
                } else {
                    IslandState.closeToIdle()
                }
            }
        }

        ListView {
            id: clipList
            width: parent.width
            height: parent.height - 74
            clip: true
            spacing: 0
            model: root.filteredItems
            delegate: Item {
                width: ListView.view.width
                height: 28

                required property var modelData
                required property int index

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    text: modelData.text
                    color: index === root.currentIndex ? Theme.accent : Theme.text
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.family
                    font.weight: index === root.currentIndex ? 600 : 400
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.currentIndex = index
                        copyCurrent()
                    }
                }
            }
        }
    }
}
