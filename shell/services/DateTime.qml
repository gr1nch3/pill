pragma Singleton
// Date/time via timedatectl. Writes try the direct call first (works for the
// active session on most polkit setups) and fall back to pkexec, which is the
// allowed escalation order for this tree.
import QtQuick
import Quickshell.Io

Item {
    id: root

    property string timezone: ""
    property bool ntp: false
    property string lastError: ""

    readonly property bool available: Integrations.has("timedatectl")

    function refresh() {
        if (!available)
            return;
        readProc.running = true;
    }

    function setTimezone(tz) {
        if (!available || tz === "")
            return;
        _run(["timedatectl", "set-timezone", tz], tz);
    }

    function setNtp(on) {
        if (!available)
            return;
        _run(["timedatectl", "set-ntp", on ? "true" : "false"], "");
    }

    function _run(args, pendingTz) {
        lastError = "";
        _pendingTz = pendingTz;
        writeProc.command = args;
        writeProc.running = true;
    }

    property string _pendingTz: ""

    Process {
        id: readProc
        command: ["timedatectl", "show", "-p", "Timezone", "-p", "NTP"]
        running: false
        stdout: SplitParser {
            onRead: function (line) {
                var i = line.indexOf("=");
                if (i < 0)
                    return;
                var k = line.slice(0, i), v = line.slice(i + 1).trim();
                if (k === "Timezone")
                    root.timezone = v;
                else if (k === "NTP")
                    root.ntp = v === "yes";
            }
        }
    }

    Process {
        id: writeProc
        command: []
        running: false
        onExited: function (code) {
            if (code === 0) {
                root.lastError = "";
                root.refresh();
                return;
            }
            if (Integrations.has("pkexec")) {
                var args = writeProc.command.slice();
                pkexecProc.command = ["pkexec"].concat(args);
                pkexecProc.running = true;
            } else {
                root.lastError = "timedatectl failed (exit " + code + ")";
            }
        }
    }

    Process {
        id: pkexecProc
        command: []
        running: false
        onExited: function (code) {
            root.lastError = code === 0 ? "" : "cancelled or failed";
            root.refresh();
        }
    }

    Component.onCompleted: root.refresh()

    Connections {
        target: Integrations
        function onReadyChanged() {
            if (Integrations.ready && root.timezone === "")
                root.refresh();
        }
    }
}
