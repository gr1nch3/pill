import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io

import "services"
import "components"
import "states"

WlrLayershell {
    id: root
    anchors.top: Config.position === "top"
    anchors.bottom: Config.position === "bottom"
    implicitWidth: Screen.width
    implicitHeight: Screen.height
    color: "transparent"
    exclusiveZone: (Config.pinned && Config.pinMode === "bar") ? 46 : 0
    // The active state pane declares its own size + pill policy (StatePane).
    readonly property var activePane: {
        var kids = pillContent.children
        for (var i = 0; i < kids.length; i++) {
            var k = kids[i]
            if (k && typeof k.handles === "function" && k.handles(IslandState.state))
                return k
        }
        return null
    }
    readonly property bool lockscreenState: IslandState.state === "lockscreen"

    // Pattern for large panes: the active pane opts in and the style is set.
    readonly property bool panePattern: Config.patternStyle !== "none"
        && activePane !== null && activePane.pattern === true

    keyboardFocus: (activePane && activePane.keyboardFocus)
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None
    layer: WlrLayer.Overlay

    property bool barVisible: true
    property QtObject polkitFlow: null

    readonly property bool isHorizontal: true

    signal mouseActivity

    readonly property alias containsMouse: pillMouse.containsMouse
    readonly property bool dropped: barVisible && !animTop.running && !animBottom.running

    readonly property real pillX: pill.x
    readonly property real pillY: pill.y
    readonly property real pillWidth: pill.width
    readonly property real pillHeight: pill.height

    // States that present as a centered panel instead of an edge pill.
    // Theme picker stays edge-anchored: it's a small dropdown, not a workspace.
    readonly property bool centered: activePane ? activePane.centered : false

    readonly property real pillScreenX: (Screen.width - pill.width) / 2
    readonly property real pillScreenY: root.centered
        ? (Screen.height - pill.height) / 2
        : Config.position === "top"
            ? 12
            : Screen.height - pill.height - 12

    mask: Region { item: pill }

    margins {
        top: Config.position === "top" ? (barVisible || IslandState.state !== "idle" ? 0 : -(pill.height + 20)) : 0
        bottom: Config.position === "bottom" ? (barVisible || IslandState.state !== "idle" ? 0 : -(pill.height + 20)) : 0
    }

    Behavior on margins.top {
        enabled: Config.position === "top"
        NumberAnimation {
            id: animTop
            duration: Theme.motion.pill
            easing.type: Easing.OutCubic
        }
    }
    Behavior on margins.bottom {
        enabled: Config.position === "bottom"
        NumberAnimation {
            id: animBottom
            duration: Theme.motion.pill
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: function(mouse) {
            if (!pill.contains(Qt.point(mouse.x, mouse.y))) {
                if (IslandState.pillExpanded) {
                    IslandState.pillExpanded = false
                } else if (IslandState.state === "auth" && root.polkitFlow) {
                    root.polkitFlow.cancelAuthenticationRequest()
                    IslandState.closeToIdle()
                } else if (IslandState.state !== "idle") {
                    IslandState.closeToIdle()
                }
            }
            mouse.accepted = false
        }
    }

    // Final (un-animated) pill geometry. The pill animates width/height
    // toward these; y is computed from the *target* height so both properties
    // settle in the same 320 ms OutCubic window instead of the y animation
    // chasing the growing height (it used to aim low, then drift back up).
    readonly property real baseTargetWidth: root.lockscreenState ? 0
        : (activePane && activePane.preferredWidth >= 0 ? activePane.preferredWidth : 360)
    readonly property real targetHeight: root.lockscreenState ? 0
        : (activePane && activePane.preferredHeight >= 0 ? activePane.preferredHeight : 420)
    // Polygon shapes eat horizontal room; grow the pill and inset the panes
    // so the background always wraps its content.
    readonly property real shapeInset: Theme.shapeInset(baseTargetWidth, targetHeight)
    readonly property real targetWidth: baseTargetWidth + 2 * shapeInset

    // Single-pass shadow (MultiEffect) instead of a Qt5Compat DropShadow
    // layer: the old effect re-blurred the whole pill in multiple passes on
    // every animation frame, which made transitions stutter.
    MultiEffect {
        source: pill
        anchors.fill: pill
        z: -1
        shadowEnabled: true
        shadowColor: "#80000000"
        shadowBlur: 0.7
        shadowVerticalOffset: 4
    }

    Rectangle {
        id: pill
        x: (parent.width - width) / 2
        y: root.centered
            ? (parent.height - root.targetHeight) / 2
            : (Config.position === "top" ? 12 : parent.height - root.targetHeight - 12)

        width: root.targetWidth
        height: root.targetHeight

        color: "transparent"

        readonly property real shapeRadius: {
            if (root.lockscreenState) return 0
            var mode = root.activePane ? root.activePane.radiusMode : "panel"
            if (mode === "pill") return height * 0.5
            if (mode === "notifications") return IslandState.pillExpanded ? Theme.shape.radius.notification : height * 0.5
            if (mode === "none") return 0
            return Theme.shape.radius.panel
        }

        // Theme geometry: rounded/rect/parallelogram/trapezoid/hex.
        SurfaceShape {
            anchors.fill: parent
            shape: Theme.shape.style
            slant: Theme.shape.slant
            radius: pill.shapeRadius
            color: Theme.surface
            borderColor: Theme.border
            borderWidth: Theme.shape.border.width
            Behavior on radius { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        }

        // Procedural pattern behind the content for large panes
        // (StatePane.pattern); the same component runs on the lock/greeter.
        PatternBackground {
            anchors.fill: parent
            anchors.margins: 1
            visible: root.panePattern && opacity > 0
            opacity: root.panePattern ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.motion.panel } }
            variant: Config.patternStyle
            spacing: Theme.patternSpacing
            strength: 0.07
            color: Theme.accent
            shape: Theme.shape.style
            slant: Theme.shape.slant
            radius: pill.shapeRadius
        }

        // One motion language: size, position and content all settle together
        // in the same 320 ms OutCubic window (no bounce; content is along for
        // the ride and overshoot made the panel wobble).
        Behavior on width  { NumberAnimation { duration: Theme.motion.pill; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Theme.motion.pill; easing.type: Easing.OutCubic } }
        Behavior on y      { NumberAnimation { duration: Theme.motion.pill; easing.type: Easing.OutCubic } }

        focus: visible
        Keys.onEscapePressed: IslandState.closeToIdle()

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: {
                if (IslandState.state === "idle") {
                    IslandState.pillHovered = containsMouse
                }
            }
            onPositionChanged: root.mouseActivity()
            onPressed: root.mouseActivity()
            onClicked: function(mouse) {
                root.mouseActivity()
                if (mouse.button === Qt.LeftButton) {
                    if (IslandState.state === "idle" || IslandState.state === "notifications") {
                        IslandState.pillExpanded = !IslandState.pillExpanded
                        mouse.accepted = true
                    } else {
                        mouse.accepted = false
                    }
                } else {
                    mouse.accepted = false
                }
            }
        }

        Item {
            id: pillContent
            anchors.fill: parent
            anchors.leftMargin: root.shapeInset
            anchors.rightMargin: root.shapeInset

            IdleState { ready: root.dropped }
            VolumeState {}
            BrightnessState {}
            SessionState {}
            CaptureState {}
            WallpaperState {}
            LauncherState {}
            NotificationsState {}
            AuthState { flow: root.polkitFlow }
            ThemeState {}
            ClipboardState {}
            NavigationState {}
            SettingsState {}
            ControlCenterState {}
            DeviceSelectState {}
            MediaPlayerState {}
        }
    }
}
