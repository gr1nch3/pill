import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Hyprland as QsHypr // ponytail: workspace OSD only; inert off Hyprland
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Widgets
import Quickshell.Io
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
    Binding {
        target: IslandState
        property: "shellActive"
        value: hotZone.barVisible
    }
    Binding {
        target: Cava
        property: "active"
        value: hotZone.barVisible
    }
    Binding {
        target: SystemStats
        property: "active"
        value: hotZone.barVisible
    }
    Binding {
        target: Power
        property: "active"
        value: hotZone.barVisible
    }

    function lockScreen() {
        if (sessionLock.locked)
            return;
        IslandState.closeToIdle();
        hotZone.barVisible = false;
        IslandState.state = "lockscreen";
        sessionLock.locked = true;
    }

    // ── Polkit authentication agent ─────────────────────────────────────────
    property bool polkitActive: polkitAgent.isActive

    onPolkitActiveChanged: {
        if (polkitActive) {
            IslandState.pillExpanded = false;
            IslandState.state = "auth";
        }
    }

    PolkitAgent {
        id: polkitAgent
        onIsRegisteredChanged: console.log("polkit: isRegistered =", isRegistered)
        Component.onCompleted: console.log("polkit: isRegistered (init) =", isRegistered)
    }

    // ── IPC ────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "bubbles"

        // One call opens any island state: `open launcher`, `open settings`,
        // `open settings theme`, `open wifi` / `open bluetooth`,
        // `open audio` / `open mic`, `open capture`. The optional arg is the
        // settings page id or the device-select type.
        function open(state: string, arg: string) {
            if (state === "" || state === "auth")
                return;
            if (state === "lockscreen") {
                root.lockScreen();
                return;
            }
            if (state === "idle") {
                IslandState.closeToIdle();
                return;
            }
            if (state === "control" || state === "controlpanel")
                state = "controlcenter";
            if (state === "settings") {
                if (arg !== undefined && arg !== "")
                    IslandState.settingsPage = arg;
            } else if (state === "wifi" || state === "bluetooth") {
                IslandState.deviceSelectType = state;
                state = "connectivity";
            } else if (state === "audio" || state === "mic") {
                IslandState.deviceSelectType = state;
                state = "audiodevice";
            } else if (state === "capture") {
                Capture.view = Capture.recording ? "recording" : "grid";
            }
            IslandState.open(state);
        }

        function setWallpaper(path: string) {
            ThemeController.setWallpaper(path);
        }
        function setTheme(name: string) {
            Theme.setTheme(name);
        }
        function brightnessUp() {
            Brightness.adjust(5);
            root.triggerOsd("brightness");
        }
        function brightnessDown() {
            Brightness.adjust(-5);
            root.triggerOsd("brightness");
        }
        function volumeUp() {
            Audio.adjust(5);
            root.triggerOsd("volume");
        }
        function volumeDown() {
            Audio.adjust(-5);
            root.triggerOsd("volume");
        }
        function volumeMute() {
            Audio.toggleMute();
            root.triggerOsd("volume");
        }
        function lockScreen() {
            root.lockScreen();
        }
        function close() {
            if (!IslandState.active)
                return;
            IslandState.closeToIdle();
        }
    }

    // ── Notifications: pill arming (server + list live in NotificationManager) ──
    Connections {
        target: NotificationManager
        function onReceived() {
            if (NotificationManager.doNotDisturb || IslandState.state === "auth" || IslandState.state === "lockscreen" || (IslandState.state === "capture" && Capture.recording))
                return;
            IslandState.pillExpanded = false;
            root.armDismiss("notifications", Config.notificationTimeout, true);
        }
        // The shown entry can be closed, expired or dismissed by its app;
        // don't leave an empty notification pill stranded on screen.
        function onEmptied() {
            if (IslandState.state === "notifications")
                IslandState.closeToIdle();
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
            if (IslandState.state === dismissState && !islandPill.containsMouse && (!needsCollapsed || !IslandState.pillExpanded))
                IslandState.closeToIdle();
        }
    }

    function armDismiss(state, ms, collapsed) {
        if (IslandState.state !== state)
            IslandState.state = state;
        dismissTimer.dismissState = state;
        dismissTimer.needsCollapsed = collapsed === true;
        dismissTimer.interval = ms;
        dismissTimer.restart();
    }

    function triggerOsd(osdState) {
        root.armDismiss(osdState, Config.osdTimeout);
    }

    Connections {
        target: Audio
        function onChanged() {
            if (IslandState.osdOwners.volume.indexOf(IslandState.state) === -1)
                root.triggerOsd("volume");
        }
    }

    Connections {
        target: Brightness
        function onChanged() {
            if (IslandState.osdOwners.brightness.indexOf(IslandState.state) === -1)
                root.triggerOsd("brightness");
        }
    }

    function triggerNav() {
        root.armDismiss("navigation", IslandState.navDismissMs);
    }

    Connections {
        target: QsHypr.Hyprland
        function onFocusedWorkspaceChanged() {
            if (IslandState.state !== "controlcenter")
                root.triggerNav();
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
            onClicked: function (mouse) {
                if (IslandState.state === "notifications" && !IslandState.pillExpanded && mouse.x >= islandPill.pillScreenX && mouse.x <= islandPill.pillScreenX + islandPill.pillWidth && mouse.y >= islandPill.pillScreenY && mouse.y <= islandPill.pillScreenY + islandPill.pillHeight) {
                    IslandState.pillExpanded = true;
                    return;
                }
                if (IslandState.pillExpanded)
                    IslandState.pillExpanded = false;
                else if (IslandState.state === "auth") {
                    if (polkitAgent && polkitAgent.flow)
                        polkitAgent.flow.cancelAuthenticationRequest();
                    IslandState.closeToIdle();
                } else {
                    IslandState.closeToIdle();
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
                    hotZone.barVisible = true;
                    IslandState.state = "idle";
                    sessionLock.locked = false;
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
                hotZone.pauseHide();
                dismissTimer.stop();
            } else {
                hotZone.resumeHide();
                if (IslandState.state === dismissTimer.dismissState)
                    dismissTimer.restart();
            }
        }
        onMouseActivity: {
            hotZone.pauseHide();
            dismissTimer.stop();
        }
    }
}
