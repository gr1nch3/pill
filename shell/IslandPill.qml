import QtQuick
import Qt5Compat.GraphicalEffects
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
    keyboardFocus: (IslandState.state === "idle" ||
                    IslandState.state === "volume" ||
                    IslandState.state === "brightness" ||
                    IslandState.state === "notifications" ||
                    IslandState.state === "navigation" ||
                    IslandState.state === "lockscreen")
        ? WlrKeyboardFocus.None
        : WlrKeyboardFocus.Exclusive
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
    readonly property var centeredStates: ["launcher", "clipboard", "wallpaper", "theme", "settings"]
    readonly property bool centered: root.centeredStates.indexOf(IslandState.state) !== -1

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
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }
    Behavior on margins.bottom {
        enabled: Config.position === "bottom"
        NumberAnimation {
            id: animBottom
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
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

    Rectangle {
        id: pill
        x: (parent.width - width) / 2
        y: root.centered
            ? (parent.height - height) / 2
            : (Config.position === "top" ? 12 : parent.height - height - 12)

        width: {
            if (IslandState.state === "lockscreen")   return 0
            if (IslandState.state === "idle")          return (root.dropped && IslandState.idleExpanded) ? (Playerctl.musicPlaying ? 520 : 360) : (Playerctl.musicPlaying ? 140 : 90)
            if (IslandState.state === "session")       return 340
            if (IslandState.state === "capture")       return captureState.captureWidth
            if (IslandState.state === "wallpaper")     return 880
            if (IslandState.state === "notifications") return IslandState.pillExpanded ? 420 : 360
            if (IslandState.state === "theme")         return 560
            if (IslandState.state === "auth")          return 360
            if (IslandState.state === "launcher")      return 560
            if (IslandState.state === "clipboard")     return 560
            if (IslandState.state === "navigation")    return navState.pillWidth
            if (IslandState.state === "settings")      return 520
            if (IslandState.state === "volume")        return 280
            if (IslandState.state === "brightness")    return 280
            if (IslandState.state === "controlcenter") return 540
            if (IslandState.state === "mediaplayer")  return 460
            if (IslandState.state === "connectivity") return 420
            if (IslandState.state === "audiodevice")  return 420
            return 360
        }
        height: {
            if (IslandState.state === "lockscreen")   return 0
            if (IslandState.state === "idle")          return IslandState.idleExpanded ? 64 : 34
            if (IslandState.state === "session")       return 70
            if (IslandState.state === "capture")       return captureState.captureHeight
            if (IslandState.state === "wallpaper")     return 560
            if (IslandState.state === "notifications") return notifState.contentHeight
            if (IslandState.state === "theme")         return themeState.contentHeight
            if (IslandState.state === "auth")          return 220
            if (IslandState.state === "launcher")      return 520
            if (IslandState.state === "clipboard")     return 420
            if (IslandState.state === "navigation")    return navState.pillHeight
            if (IslandState.state === "settings")      return settingsState.contentHeight
            if (IslandState.state === "volume")        return 48
            if (IslandState.state === "brightness")    return 48
            if (IslandState.state === "controlcenter") return 660
            if (IslandState.state === "mediaplayer")  return 200
            if (IslandState.state === "connectivity") return 400
            if (IslandState.state === "audiodevice")  return 400
            return 420
        }

        radius: {
            if (IslandState.state === "lockscreen")   return 0
            if (IslandState.state === "idle" || IslandState.state === "volume") return height * 0.5
            if (IslandState.state === "notifications") return IslandState.pillExpanded ? 20 : height * 0.5
            return 24
        }
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 4
            radius: 16
            samples: 33
            color: "#80000000"
        }

        Behavior on width  { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on y      { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

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

        IdleState { ready: root.dropped }
        VolumeState {}
        BrightnessState {}
        SessionState {}
        CaptureState { id: captureState }
        WallpaperState {}
        LauncherState {}
        NotificationsState { id: notifState }
        AuthState { flow: root.polkitFlow }
        ThemeState { id: themeState }
        ClipboardState {}
        NavigationState { id: navState }
        SettingsState { id: settingsState }
        ControlCenterState {}
        DeviceSelectState {}
        MediaPlayerState {}
    }
}
