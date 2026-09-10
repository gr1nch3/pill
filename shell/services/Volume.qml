pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int percent: 0
    property bool muted: false
    property bool micMuted: false

    property int _lastPercent: -1
    property bool _lastMuted: false

    signal changed

    Process {
        id: subscribeProc
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.indexOf("'change' on sink") >= 0) queryProc.running = true
                if (line.indexOf("'change' on source") >= 0) micQueryProc.running = true
            }
        }
    }

    // ── Output (sink) ──────────────────────────────────────────────────────
    Process {
        id: queryProc
        command: ["bash", "-c", "echo $(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+%' | head -1 | tr -d '%') $(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP '(yes|no)')"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.trim().split(" ")
                var v = parseInt(parts[0])
                if (isNaN(v)) return

                var m = parts[1] === "yes"
                root.percent = v
                root.muted = m

                if (root._lastPercent !== -1 && (v !== root._lastPercent || m !== root._lastMuted)) {
                    root.changed()
                }
                root._lastPercent = v
                root._lastMuted = m
            }
        }
    }

    // ── Input (source / mic) ───────────────────────────────────────────────
    Process {
        id: micQueryProc
        command: ["bash", "-c", "pactl get-source-mute @DEFAULT_SOURCE@ | grep -oP '(yes|no)'"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                root.micMuted = line.trim() === "yes"
            }
        }
    }

    function setPercent(pct) {
        pct = Math.max(0, Math.min(100, pct))
        setProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", pct + "%"]
        setProc.running = true
        root.percent = pct
    }

    function adjust(delta) {
        var pct = Math.max(0, Math.min(100, root.percent + delta))
        setPercent(pct)
    }

    function toggleMute() {
        muteProc.running = true
        root.muted = !root.muted
    }

    function toggleMic() {
        micMuteProc.running = true
        root.micMuted = !root.micMuted
    }

    Process { id: setProc;     command: []; running: false }
    Process { id: muteProc;    command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"];   running: false }
    Process { id: micMuteProc; command: ["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]; running: false }
}
