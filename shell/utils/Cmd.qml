// The one Process + SplitParser wrapper. Declare a command, not a process:
// one-shot via run(), poll via interval, subscribe via a long-lived command.
import QtQuick
import Quickshell.Io

Item {
    id: cmd

    // Layout positioners skip invisible items; this has no visuals anyway.
    visible: false

    property var command: []
    property bool active: true
    // 0 = one-shot (runs on activation and on run()); > 0 = poll every interval.
    property int interval: 0
    // Start automatically on activation / completion. Set false for manual run().
    property bool autorun: true

    readonly property bool running: proc.running

    // One queued re-run for one-shot commands: last command wins.
    property bool _rerun: false

    signal line(string text)
    signal stderrLine(string text)
    signal done(int exitCode)

    function run() {
        if (!command || command.length === 0) return
        if (proc.running) {
            if (interval === 0) _rerun = true
            return
        }
        proc.running = true
    }

    function stop() {
        _rerun = false
        proc.running = false
    }

    onActiveChanged: {
        if (!active) {
            stop()
            return
        }
        if (autorun && interval === 0) run()
    }

    Component.onCompleted: if (active && autorun) run()

    // Kill the child when the owning generation is torn down (config reload),
    // so long-lived commands (pactl subscribe, playerctl --follow) don't leak.
    Component.onDestruction: stop()

    Process {
        id: proc
        command: cmd.command
        running: false

        stdout: SplitParser {
            onRead: function(line) { cmd.line(line) }
        }

        stderr: SplitParser {
            onRead: function(line) { cmd.stderrLine(line) }
        }

        onExited: function(exitCode, exitStatus) {
            cmd.done(exitCode)
            if (cmd._rerun) {
                cmd._rerun = false
                cmd.run()
            }
        }
    }

    Timer {
        interval: Math.max(1, cmd.interval)
        repeat: true
        running: cmd.active && cmd.interval > 0
        onTriggered: if (!proc.running) cmd.run()
    }
}
