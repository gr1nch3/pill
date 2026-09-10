import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Hyprland // ponytail: workspace OSD only; inert off Hyprland
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Polkit

import "services"
import "components"
import "states"
import "bar"

ShellRoot {
    id: root

    // ── Bar / hot zone ──────────────────────────────────────────────────────
    HotZone {
        id: hotZone
        pillHover: islandPill.containsMouse
    }

    // Pause idle polling/animation while the bar is hidden (PRD §9.3).
    Binding { target: IslandState; property: "shellActive"; value: hotZone.barVisible }
    Binding { target: Cava; property: "active"; value: hotZone.barVisible }
    Binding { target: SystemStats; property: "active"; value: hotZone.barVisible }

    function lockScreen() {
        if (sessionLock.locked) return
        IslandState.closeToIdle()
        hotZone.barVisible = false
        IslandState.state = "lockscreen"
        sessionLock.locked = true
    }

    // ── Polkit authentication agent ─────────────────────────────────────────
    property bool polkitActive: polkitAgent.isActive

    onPolkitActiveChanged: {
        if (polkitActive) {
            IslandState.pillExpanded = false
            IslandState.state = "auth"
        }
    }

    PolkitAgent {
        id: polkitAgent
        onIsRegisteredChanged: console.log("polkit: isRegistered =", isRegistered)
        Component.onCompleted: console.log("polkit: isRegistered (init) =", isRegistered)
    }



    // ── IPC ────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "pill"

        function openLauncher() { IslandState.open("launcher") }
        function openWallpaper() { IslandState.open("wallpaper") }
        function setWallpaper(path: string) { Wallpaper.set(path) }
        function openThemePicker() { IslandState.open("theme") }
        function setTheme(name: string) { Theme.setTheme(name) }
        function openSession() { IslandState.open("session") }
        function openCapture() { IslandState.captureView = IslandState.recording ? "recording" : "grid"; IslandState.open("capture") }
        function openClipboard() { IslandState.open("clipboard") }
        function openNavigation() { IslandState.open("navigation") }
        function openSettings() { IslandState.open("settings") }
        function openConnectivity(type: string) { IslandState.deviceSelectType = type; IslandState.open("connectivity") }
        function openAudioDevice(type: string) { IslandState.deviceSelectType = type; IslandState.open("audiodevice") }
        function openBrightness() { IslandState.open("brightness") }
        function brightnessUp() { Brightness.adjust(5); root.triggerOsd("brightness") }
        function brightnessDown() { Brightness.adjust(-5); root.triggerOsd("brightness") }
        function volumeUp() { Volume.adjust(5); root.triggerOsd("volume") }
        function volumeDown() { Volume.adjust(-5); root.triggerOsd("volume") }
        function volumeMute() { Volume.toggleMute(); root.triggerOsd("volume") }
        function lockScreen() { root.lockScreen() }
        function openControl() { IslandState.open("controlcenter") }
        function close() { if (!IslandState.active) return; IslandState.closeToIdle() }
    }

    NotificationServer {
        id: notifServer
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        property bool _ready: false
        Component.onCompleted: Qt.callLater(function() { _ready = true })

        onNotification: (notif) => {
            notif.tracked = true
            NotificationManager.trackServer(notif)
            NotificationManager.add(notif.summary, notif.body, notif.appName, notif.id, notif.appIcon, notif.image, notif.urgency)
            if (_ready && !NotificationManager.doNotDisturb
                && IslandState.state !== "auth"
                && IslandState.state !== "lockscreen"
                && !(IslandState.state === "capture" && IslandState.recording)) {
                IslandState.pillExpanded = false
                root.armDismiss("notifications", Config.notificationTimeout, true)
            }
        }
    }

    // ── Auto-dismiss: one timer for every auto-closing pill state ──────────
    // ponytail: osd/notif/nav timers shared one body; arm per state + timeout.
    Timer {
        id: dismissTimer
        running: false
        property string dismissState: ""
        property bool needsCollapsed: false
        onTriggered: {
            if (IslandState.state === dismissState && !islandPill.containsMouse
                && (!needsCollapsed || !IslandState.pillExpanded))
                IslandState.closeToIdle()
        }
    }

    function armDismiss(state, ms, collapsed) {
        if (IslandState.state !== state) IslandState.state = state
        dismissTimer.dismissState = state
        dismissTimer.needsCollapsed = collapsed === true
        dismissTimer.interval = ms
        dismissTimer.restart()
    }

    function triggerOsd(osdState) {
        root.armDismiss(osdState, Config.osdTimeout)
    }

    Connections {
        target: Volume
        function onChanged() {
            if (IslandState.state !== "controlcenter" && IslandState.state !== "audiodevice" && IslandState.state !== "connectivity")
                root.triggerOsd("volume")
        }
    }

    Connections {
        target: Brightness
        function onChanged() {
            if (IslandState.state !== "controlcenter") root.triggerOsd("brightness")
        }
    }

    function triggerNav() {
        root.armDismiss("navigation", 1200)
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (IslandState.state !== "controlcenter") root.triggerNav()
        }
    }

    // ── Dismiss overlay: catches clicks outside the pill surface ──
    WlrLayershell {
        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true
        implicitWidth: Screen.width
        implicitHeight: Screen.height
        color: "transparent"
        exclusiveZone: 0
        layer: WlrLayer.Overlay
        visible: IslandState.active
        keyboardFocus: WlrKeyboardFocus.None
        focusable: false

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) {
                if (IslandState.state === "notifications" && !IslandState.pillExpanded
                    && mouse.x >= islandPill.pillScreenX && mouse.x <= islandPill.pillScreenX + islandPill.pillWidth
                    && mouse.y >= islandPill.pillScreenY && mouse.y <= islandPill.pillScreenY + islandPill.pillHeight) {
                    IslandState.pillExpanded = true
                    return
                }
                if (IslandState.pillExpanded) IslandState.pillExpanded = false
                else if (IslandState.state === "auth") {
                    if (polkitAgent && polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest()
                    IslandState.closeToIdle()
                } else {
                    IslandState.closeToIdle()
                }
            }
        }
    }

    // ── Session lock ────────────────────────────────────────────────────────
    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            LockscreenState {
                anchors.fill: parent
                onUnlocked: {
                    hotZone.barVisible = true
                    IslandState.state = "idle"
                    sessionLock.locked = false
                }
            }
        }
    }

    IslandPill {
        id: islandPill
        barVisible: hotZone.barVisible
        polkitFlow: polkitAgent.flow
        onContainsMouseChanged: {
            if (containsMouse) {
                hotZone.pauseHide()
                dismissTimer.stop()
            } else {
                hotZone.resumeHide()
                if (IslandState.state === dismissTimer.dismissState) dismissTimer.restart()
            }
        }
        onMouseActivity: {
            hotZone.pauseHide()
            dismissTimer.stop()
        }
    }
}
