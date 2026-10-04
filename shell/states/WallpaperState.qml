import QtQuick
import Qt5Compat.GraphicalEffects

import "../services"
import "../components"
import "../utils"
import "../eyes"

StatePane {
    id: pane
    stateName: "wallpaper"
    pattern: true
    centered: true
    keyboardFocus: true
    preferredWidth: 880
    preferredHeight: 560
    focus: false

    anchors.fill: parent

    Column {
        id: root
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        visible: pane.visible


        property var filteredWallpapers: []
        property int _currentIdx: 0
        property bool _userNavigated: false
        property string filterKind: "all"        // all | image | gif | video
        property string notice: ""
        // Live drag offset for the coverflow (DragHandler) and wheel accumulator
        // so trackpads step once per notch instead of flying through the library.
        property real _dragOffset: 0
        property real _wheelAccum: 0

        readonly property bool videoSupported: Integrations.canVideoWallpaper

        readonly property var kindCounts: Wallpaper.kindCounts

        function _syncIndex() {
            if (_userNavigated) return
            const searching = searchInput.text.trim() !== "" || filterKind !== "all"
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
            notice = ""
        }

        function jumpTo(index) {
            _currentIdx = Math.max(0, Math.min(index, filteredWallpapers.length - 1))
            _userNavigated = true
            notice = ""
        }

        function updateFilter() {
            filteredWallpapers = Wallpaper.query(searchInput.text, filterKind)
            if (searchInput.text.trim() !== "" || filterKind !== "all")
                _userNavigated = false
            if (_userNavigated && filteredWallpapers.length > 0)
                _currentIdx = Math.min(_currentIdx, filteredWallpapers.length - 1)
            else
                _syncIndex()
        }

        function selectCurrent() {
            const idx = _currentIdx
            if (idx < 0 || idx >= filteredWallpapers.length) return
            const wp = filteredWallpapers[idx]
            if (!wp || !wp.path) return
            if (wp.kind === "video" && !videoSupported) {
                notice = "mpvpaper is not installed — video wallpapers can't play yet"
                return
            }
            ThemeController.setWallpaper(wp.path)
            IslandState.closeToIdle()
        }

        // Same picker, different target: the lock screen + sign-in screen.
        // Videos are fine here — the lock only ever shows their still frame.
        function setLockCurrent() {
            const idx = _currentIdx
            if (idx < 0 || idx >= filteredWallpapers.length) return
            const wp = filteredWallpapers[idx]
            if (!wp || !wp.path) return
            Config.set("lockWallpaperPath", wp.path)
            notice = ""
        }

        onVisibleChanged: {
            if (visible) {
                searchInput.text = ""
                _userNavigated = false
                notice = ""
                _dragOffset = 0
                _wheelAccum = 0
                if (!Wallpaper.scanning) Wallpaper.refresh()
                updateFilter()
                searchInput.forceActiveFocus()
            }
        }

        Connections {
            target: Wallpaper
            function onWallpapersChanged() {
                if (root.visible)
                    root.updateFilter()
            }
        }

        // ── Header ─────────────────────────────────────────────────────────────
        Row {
            id: headerRow
            width: parent.width
            spacing: 10

            EyeFace {
                id: searchEye
                eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
                anchors.verticalCenter: parent.verticalCenter
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

            Text {
                id: statusText
                anchors.verticalCenter: parent.verticalCenter
                text: Wallpaper.scanning
                    ? "Scanning… " + Wallpaper.wallpapers.length
                    : root.filteredWallpapers.length + " of " + Wallpaper.wallpapers.length
                color: Theme.subtext
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
            }

            Item {
                width: parent.width - titleText.width - statusText.width - searchBox.width
                    - (searchEye.visible ? 48 + 40 : 30)
                height: 1
            }

            Rectangle {
                id: searchBox
                width: 260
                height: 28
                radius: Theme.shape.radius.control
                color: Theme.background
                border.color: Theme.border
                border.width: Theme.shape.border.width
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
                            } else if (event.key === Qt.Key_L && !ctrl) {
                                root.setLockCurrent()
                                event.accepted = true
                            }
                        }

                        onTextChanged: root.updateFilter()
                    }
                }
            }
        }

        // ── Filter chips + hint ────────────────────────────────────────────────
        Row {
            id: chipsRow
            width: parent.width
            spacing: 6

            Repeater {
                model: [
                    { key: "all",   label: "All" },
                    { key: "image", label: "Images" },
                    { key: "gif",   label: "GIFs" },
                    { key: "video", label: "Videos" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    height: 24
                    width: chipLabel.implicitWidth + 20
                    radius: Theme.shape.radius.control
                    color: root.filterKind === modelData.key
                        ? Theme.accent
                        : (chipMouse.containsMouse ? Theme.surfaceHover : Theme.background)
                    Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: modelData.label + " (" + root.kindCounts[modelData.key] + ")"
                        color: root.filterKind === modelData.key ? Theme.background : Theme.text
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.filterKind = modelData.key
                            root.updateFilter()
                        }
                    }
                }
            }

            Item { width: 1; height: 1 }

            // Second action for the same selection: send it to the lock +
            // sign-in screen instead of the desktop (L does the same).
            Rectangle {
                id: lockButton
                height: 24
                width: lockButtonLabel.implicitWidth + 20
                radius: Theme.shape.radius.control
                color: lockButtonMouse.containsMouse ? Theme.surfaceHover : Theme.background
                border.color: Theme.border
                border.width: Theme.shape.border.width
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

                Text {
                    id: lockButtonLabel
                    anchors.centerIn: parent
                    text: "Set lock (L)"
                    color: Theme.text
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                }

                MouseArea {
                    id: lockButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setLockCurrent()
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.videoSupported && root.kindCounts.video > 0
                text: "mpvpaper missing — video wallpapers disabled"
                color: Theme.danger
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.notice !== ""
                text: root.notice
                color: Theme.danger
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
            }
        }

        // ── Coverflow ──────────────────────────────────────────────────────────
        Item {
            id: viewport
            width: parent.width
            height: parent.height - headerRow.height - chipsRow.height - 16
            clip: true

            Repeater {
                model: root.filteredWallpapers

                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index

                    readonly property int _n: root.filteredWallpapers.length
                    readonly property int dist: {
                        if (_n === 0) return 0
                        var d = (index - root._currentIdx) % _n
                        if (d > _n / 2) d -= _n
                        else if (d < -_n / 2) d += _n
                        return d
                    }
                    readonly property bool isCurrent: dist === 0
                    // Constant card size, scale-driven depth: no per-frame
                    // re-layout/re-crop of the image, just a GPU transform.
                    readonly property real baseScale: isCurrent ? 1 : (Math.abs(dist) === 1 ? 0.66 : 0.5)

                    property bool hovered: false
                    property bool _born: false
                    Component.onCompleted: _born = true

                    width: 380
                    height: viewport.height
                    x: viewport.width / 2 - width / 2 + dist * 250 + root._dragOffset
                    z: 10 - Math.abs(dist)
                    scale: baseScale * (hovered ? 1.045 : 1)
                    opacity: _born && Math.abs(dist) <= 2 ? 1 : 0
                    visible: opacity > 0

                    Behavior on x {
                        enabled: !dragHandler.active
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
                    }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Loader {
                        anchors.fill: parent
                        // Only nearby cards build their content (images +
                        // mask effect); the rest stay as cheap positioned items.
                        active: Math.abs(card.dist) <= 3
                        sourceComponent: cardContent
                    }

                    Component {
                        id: cardContent
                    Rectangle {
                        id: frame
                        anchors.fill: parent
                        readonly property bool thumbReady: thumbImg.status === Image.Ready
                        readonly property bool animated: card.isCurrent && card.modelData.kind === "gif"
                        radius: Theme.shape.radius.cardLarge
                        color: Theme.background
                        border.color: card.isCurrent ? Theme.accent : Theme.border
                        border.width: card.isCurrent ? Theme.shape.border.emphasis : Theme.shape.border.width
                        Behavior on border.color { ColorAnimation { duration: Theme.motion.panel } }

                        // Loading skeleton
                        Rectangle {
                            anchors.fill: parent
                            radius: frame.radius
                            color: Theme.surfaceHover
                            visible: !frame.thumbReady
                            SequentialAnimation on opacity {
                                running: parent.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.35; duration: 700 }
                                NumberAnimation { to: 0.8; duration: 700 }
                            }
                        }

                        Image {
                            id: thumbImg
                            anchors.fill: parent
                            source: card.modelData.thumb !== "" ? "file://" + card.modelData.thumb : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 512
                            sourceSize.height: 512
                            visible: false
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }

                        AnimatedImage {
                            id: gifAnim
                            anchors.fill: parent
                            source: frame.animated ? "file://" + card.modelData.path : ""
                            playing: frame.animated
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 512
                            sourceSize.height: 512
                            visible: false
                            opacity: status === AnimatedImage.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }

                        Rectangle {
                            id: maskRect
                            anchors.fill: parent
                            radius: frame.radius
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: (gifAnim.opacity > 0) ? gifAnim : thumbImg
                            maskSource: maskRect
                        }

                        // Kind badge
                        Rectangle {
                            visible: card.modelData.kind !== "image"
                            anchors { left: parent.left; top: parent.top; margins: 10 }
                            height: 20
                            width: badgeText.implicitWidth + 14
                            radius: Theme.shape.radius.row
                            color: (card.modelData.kind === "video" && !root.videoSupported) ? Theme.dangerBg : Theme.accent

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: card.modelData.kind === "gif" ? "GIF"
                                    : (root.videoSupported ? "VIDEO" : "VIDEO · needs mpvpaper")
                                color: card.modelData.kind === "video" && !root.videoSupported ? Theme.danger : Theme.background
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                font.weight: 700
                            }
                        }

                        // Name plate
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 30
                            color: Qt.rgba(0, 0, 0, 0.55)

                            Text {
                                anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                text: card.modelData.name
                                color: "#f2f2f2"
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.family
                                elide: Text.ElideMiddle
                            }
                        }

                        // Committed marker
                        Rectangle {
                            id: committedBadge
                            visible: card.modelData.path === Wallpaper.committedWallpaper
                            anchors { right: parent.right; top: parent.top; margins: 10 }
                            width: 22; height: 22; radius: 11
                            color: Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: Theme.background
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.family
                                font.weight: 700
                            }
                        }

                        // Lock + sign-in marker (separate pick, same library)
                        Rectangle {
                            visible: Config.lockWallpaperPath !== ""
                                && card.modelData.path === Config.lockWallpaperPath
                            anchors {
                                right: committedBadge.left; top: parent.top
                                rightMargin: 6; topMargin: 10
                            }
                            width: 22; height: 22; radius: 11
                            color: Theme.surfaceHover
                            border.color: Theme.accent
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: Icons.lock
                                color: Theme.accent
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.mono
                            }
                        }

                        // Depth scrim: side cards recede without extra blur passes.
                        Rectangle {
                            anchors.fill: parent
                            radius: frame.radius
                            color: Qt.rgba(0, 0, 0, card.isCurrent ? 0
                                : Math.min(0.45, 0.16 + 0.13 * Math.abs(card.dist)))
                            Behavior on color { ColorAnimation { duration: 220 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: card.hovered = containsMouse
                            onClicked: card.isCurrent ? root.selectCurrent() : root.jumpTo(card.index)
                        }
                    }
                    }
                }
            }


            // Empty / loading states
            Column {
                anchors.centerIn: parent
                spacing: 6
                visible: root.filteredWallpapers.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Wallpaper.scanning
                        ? "Scanning the library…"
                        : (Wallpaper.wallpapers.length === 0
                            ? "No wallpapers in " + Config.wallpaperDir
                            : "Nothing matches this search/filter")
                    color: Theme.text
                    font.pixelSize: Theme.font.size.normal
                    font.family: Theme.font.family
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !Wallpaper.scanning && Wallpaper.wallpapers.length === 0
                    text: "Images, animated GIFs and videos (.gif .mp4 .webm .mkv .mov) are supported"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    const delta = wheel.angleDelta.y || wheel.angleDelta.x
                    root._wheelAccum += delta
                    const steps = Math.min(2, Math.trunc(Math.abs(root._wheelAccum) / 120))
                    if (steps > 0) {
                        const dir = root._wheelAccum < 0 ? 1 : -1
                        root._navigate(dir * steps)
                        root._wheelAccum += dir * steps * 120
                    }
                    wheel.accepted = true
                }
            }

            // Drag/swipe the coverflow: cards follow the pointer, release past
            // a threshold steps one card. Clicks still reach the card MouseAreas.
            DragHandler {
                id: dragHandler
                target: null
                xAxis.enabled: true
                yAxis.enabled: false
                property real _dx: 0

                onActiveChanged: {
                    if (active) {
                        root._dragOffset = 0
                    } else {
                        if (_dx <= -70) root._navigate(1)
                        else if (_dx >= 70) root._navigate(-1)
                        root._dragOffset = 0
                    }
                }

                onTranslationChanged: {
                    if (active) {
                        _dx = translation.x
                        root._dragOffset = translation.x * 0.45
                    }
                }
            }
        }
    }
}
