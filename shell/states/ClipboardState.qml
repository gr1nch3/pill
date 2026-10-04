import QtQuick
import QtQuick.Controls

import "../services"
import "../components"
import "../eyes"

StatePane {
    id: root
    stateName: "clipboard"
    pattern: true
    centered: true
    keyboardFocus: true
    preferredWidth: 560
    preferredHeight: 420

    anchors.fill: parent
    anchors.margins: 16

    property string filterText: ""
    property int currentIndex: 0

    readonly property var filteredItems: {
        var all = Clipboard.entries
        if (root.filterText === "") return all
        var f = root.filterText.toLowerCase()
        var result = []
        for (var i = 0; i < all.length; i++) {
            if (all[i].text.toLowerCase().indexOf(f) !== -1) result.push(all[i])
        }
        return result
    }

    function load() {
        root.currentIndex = 0
        Clipboard.refresh()
    }

    function copyCurrent() {
        var item = root.filteredItems[root.currentIndex]
        if (item) {
            Clipboard.copy(item.id)
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

    Column {
        anchors.fill: parent
        spacing: 8

        Row {
            width: parent.width
            spacing: 10

            EyeFace {
                eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
                anchors.verticalCenter: parent.verticalCenter
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
                radius: Theme.shape.radius.control
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
                    textFormat: Text.PlainText
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
