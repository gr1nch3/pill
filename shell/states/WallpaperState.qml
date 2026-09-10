import QtQuick
import Quickshell.Io

import "../services"
import "../components"
import "../utils"
import "../eyes"

Column {
    id: root
    anchors.fill: parent
    anchors.margins: 16
    spacing: 10

    opacity: IslandState.state === "wallpaper" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    property var filteredWallpapers: []
    property int _currentIdx: 0
    property bool _userNavigated: false

    readonly property int _numItems: {
        const n = Math.min(5, Math.max(1, filteredWallpapers.length))
        return n % 2 === 0 ? n - 1 : n
    }

    function _syncIndex() {
        if (_userNavigated) return
        const searching = searchInput.text.trim() !== ""
        if (!searching) {
            const idx = filteredWallpapers.findIndex(
                w => w.path === Wallpaper.committedWallpaper)
            _currentIdx = idx >= 0 ? idx : 0
        } else {
            _currentIdx = 0
        }
    }

    function _navigate(delta) {
        const n = filteredWallpapers.length
        if (n === 0) return
        _currentIdx = ((_currentIdx + delta) % n + n) % n
        _userNavigated = true
    }

    function updateFilter() {
        filteredWallpapers = Wallpaper.query(searchInput.text)
        if (searchInput.text.trim() !== "")
            _userNavigated = false
        if (_userNavigated && filteredWallpapers.length > 0)
            _currentIdx = Math.min(_currentIdx, filteredWallpapers.length - 1)
        else
            _syncIndex()
    }

    function selectCurrent() {
        const idx = _currentIdx
        if (idx >= 0 && idx < filteredWallpapers.length) {
            const wp = filteredWallpapers[idx]
            if (wp && wp.path) {
                Wallpaper.set(wp.path)
                IslandState.closeToIdle()
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = ""
            _userNavigated = false
            Wallpaper.refresh()
            updateFilter()
            searchInput.forceActiveFocus()
        }
    }

    Connections {
        target: Wallpaper
        function onWallpapersChanged() {
            if (root.visible)
                updateFilter()
        }
    }

    Row {
        width: parent.width
        spacing: 10

        Eye {
            eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
            anchors.verticalCenter: parent.verticalCenter
            moods: Theme.eyeMoods
            mood: "active"
        }

        Text {
            id: titleText
            text: "Wallpapers"
            color: Theme.text
            font.pixelSize: Theme.font.size.large
            font.family: Theme.font.family
            font.weight: 700
            anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: parent.width - titleText.width - searchBox.width - 55; height: 1 }

        Rectangle {
            id: searchBox
            width: 280
            height: 28
            radius: 8
            color: Theme.background
            border.color: Theme.border
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "󰍉"
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.mono
                    color: Theme.subtext
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchInput
                    focus: true
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 20
                    color: Theme.text
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    clip: true

                    Text {
                        anchors.fill: parent
                        text: "Search..."
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                        visible: searchInput.text.length === 0
                    }

                    Keys.onEscapePressed: IslandState.closeToIdle()
                    Keys.onPressed: function(event) {
                        const ctrl = event.modifiers & Qt.ControlModifier
                        if (event.key === Qt.Key_Left || (event.key === Qt.Key_P && ctrl)) {
                            root._navigate(-1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Right || (event.key === Qt.Key_N && ctrl)) {
                            root._navigate(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.selectCurrent()
                            event.accepted = true
                        }
                    }

                    onTextChanged: root.updateFilter()
                }
            }
        }
    }

    Item {
        width: parent.width
        height: parent.height - searchBox.height - 20

        PathView {
            id: wpList
            anchors.fill: parent
            clip: true
            model: root.filteredWallpapers
            currentIndex: root._currentIdx
            pathItemCount: root._numItems
            cacheItemCount: 4
            snapMode: PathView.SnapToItem
            interactive: false
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange

            path: Path {
                startY: wpList.height / 2
                PathAttribute { name: "itemZ"; value: 0 }
                PathLine { x: wpList.width / 2; relativeY: 0 }
                PathAttribute { name: "itemZ"; value: 1 }
                PathLine { x: wpList.width; relativeY: 0 }
            }

            delegate: Item {
                id: del
                readonly property bool _isCenter: PathView.isCurrentItem
                readonly property int _itemW: 200
                readonly property int _centerW: 260
                implicitWidth: _isCenter ? _centerW : _itemW
                implicitHeight: wpList.height
                required property var modelData

                z: PathView.itemZ ?? 0
                scale: _isCenter ? 1 : PathView.onPath ? 0.8 : 0
                opacity: PathView.onPath ? 1 : 0

                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                Behavior on implicitWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Image {
                    id: wpThumb
                    anchors.centerIn: parent
                    width: parent.width - 12
                    height: parent.height - 12
                    source: "file://" + modelData.thumb
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 0
                    sourceSize.height: 0
                }

                Rectangle {
                    anchors.fill: wpThumb
                    radius: 6
                    color: "transparent"
                    border.color: _isCenter ? Theme.accent : "transparent"
                    border.width: 2

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    visible: modelData.path === Wallpaper.committedWallpaper
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                    border.color: Theme.accent
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: Theme.accent
                        font.pixelSize: 24
                        font.weight: 700
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Wallpaper.set(modelData.path)
                        IslandState.closeToIdle()
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: function(wheel) {
                const delta = wheel.angleDelta.y || wheel.angleDelta.x
                if (delta > 0)
                    root._navigate(-1)
                else if (delta < 0)
                    root._navigate(1)
            }
        }
    }
}
