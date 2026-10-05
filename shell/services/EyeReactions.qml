pragma Singleton
// One place where shell events become momentary eye expressions/motion. Views
// keep their contextual mood (`EyeFace.baseMood`); a reaction temporarily
// overrides it and then clears. Callers may also startle()/blink()/glance()
// directly.
import QtQuick
import Quickshell.Wayland

Item {
    id: root

    // "" = no override; otherwise a mood key from Theme.eyeMoods.
    property string mood: ""
    // True while a startle is showing (used to pop the face into the
    // collapsed pill).
    readonly property bool active: mood !== ""
    // Bumped on every reaction; EyeFace listens for the change.
    property int startled: 0
    property int blinks: 0
    property int glanced: 0
    property real glanceDir: 1
    // True after a stretch without input; EyeFace swaps to the sleepy variant.
    property bool sleeping: false

    function startle(mood_) {
        if (mood_) root.mood = mood_
        root.startled++
        clearTimer.restart()
    }

    function blink() { root.blinks++ }

    function glance(dir) {
        root.glanceDir = dir >= 0 ? 1 : -1
        root.glanced++
    }

    function clear() { root.mood = "" }

    Timer {
        id: clearTimer
        interval: 1600
        onTriggered: root.clear()
    }

    // Three minutes without input → sleepy eyelids; any activity blinks them
    // back awake.
    IdleMonitor {
        timeout: 180
        onIsIdleChanged: {
            root.sleeping = isIdle
            if (!isIdle) root.blink()
        }
    }

    // ── Event hooks ───────────────────────────────────────────────────────
    // Notifications: urgency picks the motion. Critical startles, normal gets
    // a short "active" beam, low just blinks. DND stays silent.
    Connections {
        target: NotificationManager
        function onReceived() {
            if (NotificationManager.doNotDisturb) return
            // _add prepends, so [0] is the notification that just arrived
            var list = NotificationManager.notificationList
            var urgency = list.length > 0 ? (list[0].urgency || 0) : 0
            if (urgency >= 2) root.startle("alert")
            else if (urgency === 1) root.startle("active")
            else root.blink()
        }
    }

    // Volume / brightness keys get a quick blink, not a full startle.
    Connections {
        target: Audio
        function onChanged() { root.blink() }
    }
    Connections {
        target: Brightness
        function onChanged() { root.blink() }
    }

    // Plugging in is good news; hitting the last 15% is not.
    property bool _batterySeen: false
    Connections {
        target: Battery
        function onStatusChanged() {
            if (!root._batterySeen) { root._batterySeen = true; return }
            if (Battery.status === "Charging")
                root.startle("active")
            else if (Battery.status === "Discharging" && Battery.percent <= 15)
                root.startle("alert")
        }
    }

    // Playback starting wakes the face up (beat-sync itself is per-view).
    Connections {
        target: Playerctl
        function onMusicPlayingChanged() {
            if (Playerctl.musicPlaying)
                root.startle("active")
        }
    }

    // Recording starts with an alert (the collapsed pill grows a red-dot
    // face while it runs); stopping gets a relieved blink.
    Connections {
        target: Capture
        function onRecordingChanged() {
            if (Capture.recording) root.startle("alert")
            else root.blink()
        }
    }

    // Workspace switch: glance the way the number moved.
    property int _lastWorkspace: -1
    Component.onCompleted: root._lastWorkspace = Workspaces.activeId
    Connections {
        target: Workspaces
        function onActiveIdChanged() {
            if (root._lastWorkspace !== -1 && Workspaces.activeId !== root._lastWorkspace)
                root.glance(Workspaces.activeId > root._lastWorkspace ? 1 : -1)
            root._lastWorkspace = Workspaces.activeId
        }
    }
}
