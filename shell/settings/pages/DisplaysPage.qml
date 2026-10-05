// Displays, visual first: a to-scale arrange canvas (drag a screen, edges snap,
// drops close gaps), then the selected display's mode gallery, scale and
// rotation as pictures instead of rows. Geometry helpers live in
// utils/Arrange.js (unit-tested); all compositor writes still go through
// Hyprland.setMonitor*.
import QtQuick

import "../../components"
import "../../services"
import "../../utils/Arrange.js" as Arrange
import "../controls"

SettingsPage {
    id: root

    actions: [
        { label: "Extend", icon: "󰁔", onTrigger: root.extend },
        { label: "Tidy", icon: "󰑓", onTrigger: root.tidy }
    ]

    // ── arrangement state ──────────────────────────────────────────────────
    // draft: [{ name, x, y, w, h }] logical footprints, mutated in place while
    // dragging; `tick` re-evaluates the bindings that read it (a new array
    // model would rebuild the delegates mid-drag).
    property var draft: []
    property string selected: ""
    property bool dragging: false
    property int tick: 0
    property var frozen: ({ "k": 0.1, "ox": 0, "oy": 0 })

    readonly property var selectedMonitor: {
        for (var i = 0; i < Hyprland.monitors.length; i++)
            if (Hyprland.monitors[i].name === root.selected) return Hyprland.monitors[i]
        return null
    }

    function refresh() {
        Hyprland.refreshMonitors()
    }

    function findDraft(name) {
        for (var i = 0; i < root.draft.length; i++)
            if (root.draft[i].name === name) return i
        return -1
    }

    function sync() {
        if (root.dragging || !Hyprland.monitorsAvailable) return
        var out = []
        for (var i = 0; i < Hyprland.monitors.length; i++) {
            var m = Hyprland.monitors[i]
            if (m.disabled) continue
            out.push({ name: m.name, x: Math.round(m.x), y: Math.round(m.y), w: footW(m), h: footH(m) })
        }
        root.draft = out
        if (root.findDraft(root.selected) < 0)
            root.selected = out.length > 0 ? out[0].name : ""
        root.tick++
    }

    Connections {
        target: Hyprland
        function onMonitorsChanged() { root.sync() }
    }

    Component.onCompleted: sync()

    // ── footprints & canvas math ───────────────────────────────────────────
    // hyprctl reports the UNtransformed pixel size; a rotated monitor's
    // footprint swaps axes (a 1920x1080 portrait occupies 1080x1920).
    function footW(m) {
        var s = Number(m.scale) || 1
        var w = (Number(m.width) || 0) / s, h = (Number(m.height) || 0) / s
        return Math.max(1, Math.round((Number(m.transform) || 0) % 2 === 1 ? h : w))
    }

    function footH(m) {
        var s = Number(m.scale) || 1
        var w = (Number(m.width) || 0) / s, h = (Number(m.height) || 0) / s
        return Math.max(1, Math.round((Number(m.transform) || 0) % 2 === 1 ? w : h))
    }

    function bbox() {
        var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9
        for (var i = 0; i < root.draft.length; i++) {
            var m = root.draft[i]
            minX = Math.min(minX, m.x); minY = Math.min(minY, m.y)
            maxX = Math.max(maxX, m.x + m.w); maxY = Math.max(maxY, m.y + m.h)
        }
        if (root.draft.length === 0) return { x: 0, y: 0, w: 1, h: 1 }
        return { x: minX, y: minY, w: Math.max(1, maxX - minX), h: Math.max(1, maxY - minY) }
    }

    // Fit the layout to 84% of the canvas, centred; frozen during a drag so the
    // zoom never shifts under the cursor.
    function computeView(cw, ch) {
        var b = bbox()
        if (cw <= 0 || ch <= 0) return { k: 0.05, ox: 0, oy: 0 }
        var k = Math.min(cw * 0.84 / b.w, ch * 0.84 / b.h)
        if (!isFinite(k) || k <= 0) k = 0.05
        return { k: k, ox: (cw - b.w * k) / 2 - b.x * k, oy: (ch - b.h * k) / 2 - b.y * k }
    }

    readonly property var view: {
        void root.tick
        if (root.dragging) return root.frozen
        return root.computeView(canvasArea.width, canvasArea.height)
    }

    function nearestSnap(val, cands, th) {
        var best = val, bd = th
        for (var i = 0; i < cands.length; i++) {
            var d = Math.abs(val - cands[i])
            if (d < bd) { bd = d; best = cands[i] }
        }
        return best
    }

    function indexOfName(name) {
        for (var i = 0; i < root.draft.length; i++)
            if (root.draft[i].name === name) return i
        return -1
    }

    // ── drag lifecycle ─────────────────────────────────────────────────────
    function dragStart(name) {
        root.frozen = root.computeView(canvasArea.width, canvasArea.height)
        root.dragging = true
        root.selected = name
        root.tick++
    }

    function dragMove(name, dx, dy) {
        var i = root.indexOfName(name)
        if (i < 0) return
        root.draft[i].x += dx
        root.draft[i].y += dy
        root.tick++
    }

    function dragEnd(name) {
        var i = root.indexOfName(name)
        if (i >= 0) {
            var m = root.draft[i]
            var k = root.computeView(canvasArea.width, canvasArea.height).k
            // zoom-independent fine snap: ~24 screen px
            var th = Math.max(8, 24 / Math.max(0.0001, k))
            var xs = [0], ys = [0]
            for (var j = 0; j < root.draft.length; j++) {
                if (j === i) continue
                var o = root.draft[j]
                xs.push(o.x, o.x + o.w, o.x - m.w)
                ys.push(o.y, o.y + o.h, o.y - m.h)
            }
            m.x = Math.round(nearestSnap(m.x, xs, th))
            m.y = Math.round(nearestSnap(m.y, ys, th))
            if (!Arrange.touchesAny(root.draft, i))
                Arrange.attachFlush(root.draft, i)
            m.x = Math.round(m.x); m.y = Math.round(m.y)
            root.draft = root.draft.slice()
            Hyprland.setMonitorPosition(m.name, m.x, m.y)
            settle.restart()
        }
        root.dragging = false
        root.tick++
    }

    function applyPositions() {
        for (var i = 0; i < root.draft.length; i++)
            Hyprland.setMonitorPosition(root.draft[i].name, root.draft[i].x, root.draft[i].y)
        settle.restart()
    }

    // One flush left-to-right row in current order.
    function extend() {
        var x = 0
        for (var i = 0; i < root.draft.length; i++) {
            var m = root.draft[i]
            m.x = x; m.y = 0
            x += m.w
        }
        root.draft = root.draft.slice()
        root.tick++
        applyPositions()
    }

    function tidy() {
        if (Arrange.tidyGaps(root.draft)) {
            root.draft = root.draft.slice()
            root.tick++
            applyPositions()
        }
    }

    // fixed-delay readback after writes settle; the canvas syncs on arrival.
    Timer {
        id: settle
        interval: 700
        onTriggered: Hyprland.refreshMonitors()
    }

    readonly property string mainName: {
        void root.tick
        return Arrange.deriveMain(root.draft)
    }

    // ── mode catalogue ─────────────────────────────────────────────────────
    function parseMode(s) {
        var m = /^(\d+)x(\d+)@([\d.]+)/.exec(String(s))
        return m ? { w: parseInt(m[1]), h: parseInt(m[2]), hz: parseFloat(m[3]) } : null
    }

    // One card per resolution, refresh rates as chips inside it; widest first.
    readonly property var modeGroups: {
        var sm = root.selectedMonitor
        var modes = sm ? (sm.availableModes || []) : []
        var groups = [], byKey = {}
        for (var i = 0; i < modes.length; i++) {
            var p = parseMode(modes[i])
            if (!p) continue
            var key = p.w + "x" + p.h
            if (!byKey[key]) {
                byKey[key] = { w: p.w, h: p.h, area: p.w * p.h, rates: [] }
                groups.push(byKey[key])
            }
            byKey[key].rates.push(p.hz)
        }
        groups.sort(function(a, b) { return b.area - a.area })
        for (i = 0; i < groups.length; i++) {
            var seen = {}
            groups[i].rates = groups[i].rates.filter(function(hz) {
                var k = hz.toFixed(1)
                if (seen[k]) return false
                seen[k] = true
                return true
            }).sort(function(a, b) { return b - a })
        }
        return groups
    }

    function isCurrentMode(g, hz) {
        var sm = root.selectedMonitor
        if (!sm) return false
        return sm.width === g.w && sm.height === g.h
            && Math.abs(Number(sm.refreshRate) - hz) < 0.6
    }

    function applyMode(g, hz) {
        if (!root.selectedMonitor) return
        Hyprland.setMonitorMode(root.selectedMonitor.name, g.w + "x" + g.h + "@" + Number(hz).toFixed(2))
        settle.restart()
    }

    function screenFit(w, h, maxW, maxH) {
        var r = w / Math.max(1, h)
        return r > maxW / maxH
            ? { w: maxW, h: Math.round(maxW / r) }
            : { w: Math.round(maxH * r), h: maxH }
    }

    // ── scale / rotation ───────────────────────────────────────────────────
    readonly property var scaleValues: [1, 1.25, 1.5, 1.75, 2]

    function currentScaleIndex(m) {
        var best = 0, dist = 99
        for (var i = 0; i < scaleValues.length; i++) {
            var d = Math.abs(scaleValues[i] - Number(m.scale))
            if (d < dist) { dist = d; best = i }
        }
        return best
    }

    function logicalSize(m) {
        if (!m) return ""
        var s = Number(m.scale) || 1
        var w = Math.round((Number(m.width) || 0) / s)
        var h = Math.round((Number(m.height) || 0) / s)
        return (Number(m.transform) % 2 === 1 ? h + "×" + w : w + "×" + h)
    }

    // ───────────────────────────────────────────────────────────────────────
    SettingSection {
        icon: "󰍹"; label: "ARRANGE"
        description: "Drag a display to lay it out — edges snap, and a drop closes any gap the cursor couldn't cross."
    }

    SettingNote {
        visible: !Hyprland.monitorsAvailable
        text: "No monitors detected via hyprctl.\nThe monitor rule is applied at runtime and re-applied when the shell starts."
    }

    // ── the arrange canvas ─────────────────────────────────────────────────
    Rectangle {
        id: canvasCard
        width: parent.width
        height: visible ? 292 : 0
        visible: Hyprland.monitorsAvailable
        radius: Theme.shape.radius.card
        color: Theme.background
        border.width: Theme.shape.border.width
        border.color: Theme.border

        Text {
            anchors { left: parent.left; top: parent.top; leftMargin: 12; topMargin: 12 }
            text: "LAYOUT"
            color: Theme.subtext
            font.pixelSize: Theme.font.size.caption
            font.family: Theme.font.family
            font.weight: 700
            font.letterSpacing: 0.8
        }

        Rectangle {
            id: canvasArea
            anchors {
                left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom
                leftMargin: 10; rightMargin: 10; topMargin: 34; bottomMargin: 10
            }
            radius: Theme.shape.radius.row
            color: Theme.surface
            border.width: Theme.shape.border.width
            border.color: Theme.border
            clip: true

            PatternBackground {
                anchors.fill: parent
                variant: "dots"
                spacing: 22
                strength: 0.07
                color: Theme.accent
                shape: "rounded"
                radius: parent.radius
            }

            // origin crosshair: (0,0) in layout coordinates.
            Item {
                x: root.view.ox
                y: root.view.oy
                width: 1; height: 1
                Rectangle {
                    anchors.centerIn: parent
                    width: 7; height: 1; color: Theme.subtext; opacity: 0.6
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 1; height: 7; color: Theme.subtext; opacity: 0.6
                }
            }

            Text {
                anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                text: Hyprland.monitorsAvailable ? "DRAG TO ARRANGE" : ""
                color: Theme.subtext
                opacity: 0.7
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.family
                font.weight: 700
                font.letterSpacing: 0.8
            }

            Repeater {
                model: root.draft.length

                delegate: Item {
                    id: tile
                    required property int index
                    readonly property var m: root.draft[index]
                    readonly property bool on: !!tile.m && root.selected === tile.m.name
                    readonly property bool isMain: !!tile.m && tile.m.name === root.mainName

                    visible: !!tile.m
                    x: tile.m ? tile.m.x * root.view.k + root.view.ox : 0
                    y: tile.m ? tile.m.y * root.view.k + root.view.oy : 0
                    width: tile.m ? Math.max(44, tile.m.w * root.view.k) : 44
                    height: tile.m ? Math.max(34, tile.m.h * root.view.k) : 34
                    scale: dragH.active ? 1.05 : (hoverH.hovered ? 1.02 : 1)
                    opacity: tile.entrance
                    transformOrigin: Item.Center

                    Behavior on scale { NumberAnimation { duration: Theme.motion.normal; easing.type: Easing.OutCubic } }
                    Behavior on x { enabled: !dragH.active && !root.dragging; NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
                    Behavior on y { enabled: !dragH.active && !root.dragging; NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic } }

                    // staged entrance so the layout assembles itself on open
                    property real entrance: 0
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: Math.min(240, tile.index * 45) }
                        NumberAnimation {
                            target: tile; property: "entrance"
                            to: 1; duration: 320; easing.type: Easing.OutCubic
                        }
                    }

                    // outer halo: selection glow, sized like a double bezel
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: Theme.shape.radius.row + 3
                        color: "transparent"
                        border.width: tile.on ? 1 : 0
                        border.color: Theme.accent
                        opacity: tile.on ? 0.35 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.motion.hover } }
                    }

                    Rectangle {
                        id: core
                        anchors.fill: parent
                        radius: Theme.shape.radius.row
                        color: tile.on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                            : (hoverH.hovered ? Theme.surfaceHover : Theme.background)
                        border.width: tile.on ? Theme.shape.border.emphasis : Theme.shape.border.width
                        border.color: tile.on ? Theme.accent : Theme.border
                        Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                        Behavior on border.color { ColorAnimation { duration: Theme.motion.hover } }
                        Behavior on border.width { NumberAnimation { duration: Theme.motion.hover } }

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            spacing: 1

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: tile.m ? tile.m.name : ""
                                color: Theme.text
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.family
                                font.weight: 700
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: tile.m ? tile.m.w + "×" + tile.m.h : ""
                                color: Theme.subtext
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.mono
                            }
                        }

                        Text {
                            visible: tile.isMain
                            anchors { left: parent.left; top: parent.top; margins: 4 }
                            text: "MAIN"
                            color: Theme.accent
                            font.pixelSize: Theme.font.size.caption
                            font.family: Theme.font.family
                            font.weight: 800
                            font.letterSpacing: 0.6
                        }
                    }

                    HoverHandler { id: hoverH; cursorShape: Qt.PointingHandCursor }

                    DragHandler {
                        id: dragH
                        target: null
                        property real lastX: 0
                        property real lastY: 0
                        onActiveChanged: {
                            if (active) {
                                lastX = 0; lastY = 0
                                root.dragStart(tile.m.name)
                            } else {
                                root.dragEnd(tile.m.name)
                            }
                        }
                        onTranslationChanged: {
                            var dx = translation.x - lastX
                            var dy = translation.y - lastY
                            lastX = translation.x
                            lastY = translation.y
                            root.dragMove(tile.m.name, dx / root.view.k, dy / root.view.k)
                        }
                    }

                    TapHandler { onTapped: root.selected = tile.m.name }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.draft.length === 0
                text: "No displays detected"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
            }
        }
    }

    // ── selected display ───────────────────────────────────────────────────
    SettingSection {
        icon: "󰍹"; label: "DISPLAY"
        description: root.selectedMonitor
            ? "Configuring " + root.selectedMonitor.name
                + (root.selectedMonitor.description ? " — " + root.selectedMonitor.description : "")
            : "Select a display on the canvas."
        visible: Hyprland.monitorsAvailable
    }

    // Hero card (double bezel: shell + core)
    Rectangle {
        width: parent.width
        height: visible ? 82 : 0
        visible: !!root.selectedMonitor
        radius: Theme.shape.radius.card
        color: Theme.background
        border.width: Theme.shape.border.width
        border.color: Theme.border

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: Theme.shape.radius.card - 2
            color: Theme.surface
            clip: true

            Row {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 12

                Rectangle {
                    width: 46; height: 46
                    radius: Theme.shape.radius.control
                    color: Theme.background
                    border.width: Theme.shape.border.width
                    border.color: Theme.border
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "󰍹"
                        color: Theme.accent
                        font.pixelSize: Theme.font.size.xlarge
                        font.family: Theme.font.mono
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Row {
                        spacing: 8

                        Text {
                            text: root.selectedMonitor ? root.selectedMonitor.name : ""
                            color: Theme.text
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.family
                            font.weight: 700
                        }

                        Rectangle {
                            visible: root.selectedMonitor && root.selectedMonitor.name === root.mainName
                            anchors.verticalCenter: parent.verticalCenter
                            width: mainLabel.implicitWidth + 12
                            height: 18
                            radius: Theme.shape.radius.hairline
                            color: Theme.accent
                            Text {
                                id: mainLabel
                                anchors.centerIn: parent
                                text: "MAIN"
                                color: Theme.background
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                font.weight: 800
                                font.letterSpacing: 0.6
                            }
                        }
                    }

                    Text {
                        text: root.selectedMonitor
                            ? root.selectedMonitor.description + " · " + root.logicalSize(root.selectedMonitor) + " logical"
                            : ""
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                    }
                }
            }

            Column {
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 3

                Text {
                    text: root.selectedMonitor
                        ? root.selectedMonitor.width + "×" + root.selectedMonitor.height : ""
                    color: Theme.text
                    font.pixelSize: Theme.font.size.normal
                    font.family: Theme.font.mono
                    font.weight: 600
                    anchors.right: parent.right
                }

                Text {
                    text: root.selectedMonitor
                        ? Number(root.selectedMonitor.refreshRate).toFixed(0) + " Hz · "
                            + Number(root.selectedMonitor.scale).toFixed(2) + "×" : ""
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.mono
                    anchors.right: parent.right
                }
            }
        }
    }

    // ── mode gallery ───────────────────────────────────────────────────────
    SettingSection {
        icon: "󰒺"; label: "RESOLUTION"
        description: "Pick a mode — the preview keeps its true aspect ratio."
        visible: !!root.selectedMonitor
    }

    Grid {
        id: modeGrid
        width: parent.width
        columns: 3
        spacing: 8
        visible: !!root.selectedMonitor

        Repeater {
            model: root.modeGroups

            delegate: Rectangle {
                id: modeCard
                required property var modelData
                readonly property bool hovered: modeHover.hovered
                readonly property var fit: root.screenFit(modelData.w, modelData.h, 84, 48)
                readonly property bool activeGroup: root.selectedMonitor
                    && root.selectedMonitor.width === modelData.w
                    && root.selectedMonitor.height === modelData.h

                width: (modeGrid.width - modeGrid.spacing * 2) / 3
                height: modeCol.implicitHeight + 20
                radius: Theme.shape.radius.row
                color: activeGroup ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
                    : (hovered ? Theme.surfaceHover : Theme.surface)
                border.width: activeGroup ? Theme.shape.border.emphasis : Theme.shape.border.width
                border.color: activeGroup ? Theme.accent : (hovered ? Theme.subtext : Theme.border)
                scale: hovered ? 1.02 : 1
                Behavior on scale { NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                Behavior on border.color { ColorAnimation { duration: Theme.motion.hover } }
                Behavior on border.width { NumberAnimation { duration: Theme.motion.hover } }

                Column {
                    id: modeCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 6

                    // aspect-true mini screen
                    Item {
                        width: parent.width
                        height: 48

                        Rectangle {
                            anchors.centerIn: parent
                            width: modeCard.fit.w
                            height: modeCard.fit.h
                            radius: 3
                            color: modeCard.activeGroup ? Theme.highlight
                                : Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.55)
                            border.width: modeCard.activeGroup ? 2 : 1
                            border.color: modeCard.activeGroup ? Theme.accent : Theme.border
                            Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                            Behavior on border.color { ColorAnimation { duration: Theme.motion.hover } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰍹"
                                color: modeCard.activeGroup ? Theme.accent : Theme.subtext
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.mono
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: modeCard.modelData.w + "×" + modeCard.modelData.h
                        color: Theme.text
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                        font.weight: modeCard.activeGroup ? 700 : 500
                    }

                    Flow {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: modeCard.modelData.rates

                            delegate: Rectangle {
                                id: rateChip
                                required property real modelData
                                readonly property bool on: root.isCurrentMode(modeCard.modelData, rateChip.modelData)
                                width: rateText.implicitWidth + 12
                                height: 20
                                radius: Theme.shape.radius.hairline
                                color: on ? Theme.accent
                                    : (rateHover.hovered ? Theme.highlight : Theme.background)
                                border.width: on ? 0 : Theme.shape.border.width
                                border.color: Theme.border
                                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                                Text {
                                    id: rateText
                                    anchors.centerIn: parent
                                    text: Number(rateChip.modelData).toFixed(
                                        Number(rateChip.modelData) % 1 === 0 ? 0 : 1) + " Hz"
                                    color: on ? Theme.background : Theme.text
                                    font.pixelSize: Theme.font.size.caption
                                    font.family: Theme.font.mono
                                    font.weight: on ? 700 : 400
                                }

                                HoverHandler { id: rateHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.applyMode(modeCard.modelData, rateChip.modelData) }
                            }
                        }
                    }
                }

                HoverHandler { id: modeHover; cursorShape: Qt.PointingHandCursor }

                // selected check pops in
                Rectangle {
                    visible: opacity > 0
                    opacity: modeCard.activeGroup ? 1 : 0
                    anchors { right: parent.right; top: parent.top; margins: 8 }
                    width: 16; height: 16; radius: 8
                    color: Theme.accent
                    scale: modeCard.activeGroup ? 1 : 0.4
                    Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
                    Behavior on scale { NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutBack } }
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: Theme.background
                        font.pixelSize: Theme.font.size.caption
                        font.family: Theme.font.family
                        font.weight: 800
                    }
                }
            }
        }
    }

    // ── scale + rotation, two cards side by side ────────────────────────────
    Row {
        width: parent.width
        spacing: 8
        visible: !!root.selectedMonitor

        // scale
        Rectangle {
            width: (parent.width - 8) * 0.58
            height: 118
            radius: Theme.shape.radius.card
            color: Theme.surface
            border.width: Theme.shape.border.width
            border.color: Theme.border

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "SCALE"
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.caption
                        font.family: Theme.font.family
                        font.weight: 700
                        font.letterSpacing: 0.8
                    }

                    Text {
                        text: root.selectedMonitor ? root.logicalSize(root.selectedMonitor) + " logical" : ""
                        color: Theme.accent
                        font.pixelSize: Theme.font.size.caption
                        font.family: Theme.font.mono
                        font.weight: 700
                        Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                    }
                }

                SettingChips {
                    options: ["100%", "125%", "150%", "175%", "200%"]
                    currentIndex: root.selectedMonitor ? root.currentScaleIndex(root.selectedMonitor) : 0
                    onSelected: function(index) {
                        if (root.selectedMonitor) {
                            Hyprland.setMonitorScale(root.selectedMonitor.name, root.scaleValues[index])
                            settle.restart()
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "Logical desktop pixels apps render into."
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.family
                }
            }
        }

        // rotation: pictures, not words
        Rectangle {
            width: parent.width - (parent.width - 8) * 0.58 - 8
            height: 118
            radius: Theme.shape.radius.card
            color: Theme.surface
            border.width: Theme.shape.border.width
            border.color: Theme.border

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 8

                Text {
                    text: "ROTATION"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.family
                    font.weight: 700
                    font.letterSpacing: 0.8
                }

                Row {
                    spacing: 6

                    Repeater {
                        model: [0, 1, 2, 3]

                        delegate: Rectangle {
                            id: rotCard
                            required property int modelData
                            readonly property bool on: root.selectedMonitor
                                && (Number(root.selectedMonitor.transform) || 0) === rotCard.modelData
                            readonly property bool odd: rotCard.modelData % 2 === 1

                            width: 40; height: 40
                            radius: Theme.shape.radius.control
                            color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                                : (rotHover.hovered ? Theme.surfaceHover : Theme.background)
                            border.width: on ? Theme.shape.border.emphasis : Theme.shape.border.width
                            border.color: on ? Theme.accent : Theme.border
                            Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                            Behavior on border.color { ColorAnimation { duration: Theme.motion.hover } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: rotCard.odd ? 16 : 22
                                height: rotCard.odd ? 22 : 16
                                radius: 2
                                color: rotCard.on ? Theme.accent : Theme.highlight
                                Behavior on width { NumberAnimation { duration: Theme.motion.normal; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: Theme.motion.normal; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                            }

                            HoverHandler { id: rotHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (root.selectedMonitor) {
                                        Hyprland.setMonitorTransform(root.selectedMonitor.name, rotCard.modelData)
                                        settle.restart()
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    text: root.selectedMonitor
                        ? ["Normal", "90°", "180°", "270°"][Math.min(3, Number(root.selectedMonitor.transform) || 0)]
                        : ""
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.family
                }
            }
        }
    }
}
