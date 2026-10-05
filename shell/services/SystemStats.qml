pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property real ramPercent: 0
    property real cpuPercent: 0
    property real diskPercent: 0
    property string diskTotal: ""
    property string diskUsed: ""

    property real _cpuTotal: 0
    property real _cpuIdle: 0

    Process {
        id: ramProc
        command: ["bash", "-c", "free | grep Mem"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var parts = line.trim().split(/\s+/);
                var total = parseFloat(parts[1]);
                var available = parseFloat(parts[6]);
                if (total > 0)
                    root.ramPercent = Math.round(((total - available) / total) * 100);
            }
        }
    }

    Process {
        id: cpuProc
        command: ["bash", "-c", "grep '^cpu ' /proc/stat"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var parts = line.trim().split(/\s+/);
                var idle = parseFloat(parts[4]) || 0;
                var total = 0;
                for (var i = 1; i < parts.length; i++)
                    total += parseFloat(parts[i]) || 0;

                var prevTotal = root._cpuTotal;
                var prevIdle = root._cpuIdle;
                if (prevTotal > 0 && total > prevTotal) {
                    root.cpuPercent = Math.round((1 - (idle - prevIdle) / (total - prevTotal)) * 100);
                }
                root._cpuTotal = total;
                root._cpuIdle = idle;
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -h / | tail -1 | awk '{print $5, $3, $2}'"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var parts = line.trim().split(/\s+/);
                if (parts.length >= 3) {
                    root.diskPercent = parseInt(parts[0]) || 0;
                    root.diskUsed = parts[1] || "";
                    root.diskTotal = parts[2] || "";
                }
            }
        }
    }

    // Set false by shell.qml while the bar is hidden — pauses stat polling.
    property bool active: true

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        onTriggered: {
            ramProc.running = true;
            cpuProc.running = true;
            diskProc.running = true;
        }
    }
}
