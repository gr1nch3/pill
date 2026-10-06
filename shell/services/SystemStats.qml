pragma Singleton
// RAM / CPU / disk, one poll process per tick (a single bash that reads
// /proc directly and runs df once) instead of one Process per metric.
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
        id: statsProc
        // awk reads /proc/meminfo and /proc/stat without spawning free/grep;
        // df's header is skipped in the parser, not by tail.
        command: ["bash", "-c", "awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if(t>0) printf \"RAM %d\\n\", (t-a)/t*100}' /proc/meminfo\n" + "awk '/^cpu /{idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print \"CPU\", total, idle}' /proc/stat\n" + "df -h /\n"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var parts = line.trim().split(/\s+/);
                if (parts[0] === "RAM") {
                    root.ramPercent = parseInt(parts[1]) || 0;
                } else if (parts[0] === "CPU") {
                    var total = parseFloat(parts[1]) || 0;
                    var idle = parseFloat(parts[2]) || 0;
                    if (root._cpuTotal > 0 && total > root._cpuTotal)
                        root.cpuPercent = Math.round((1 - (idle - root._cpuIdle) / (total - root._cpuTotal)) * 100);
                    root._cpuTotal = total;
                    root._cpuIdle = idle;
                } else if (parts.length >= 6 && parts[parts.length - 1] === "/") {
                    // Filesystem Size Used Avail Use% Mounted-on
                    root.diskPercent = parseInt(parts[4]) || 0;
                    root.diskUsed = parts[2] || "";
                    root.diskTotal = parts[1] || "";
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
        onTriggered: statsProc.running = true
    }
}
