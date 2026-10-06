pragma Singleton
// Battery percent + status from /sys, one bash per poll (read is a builtin,
// so no cat/free spawns); the status line can contain spaces ("Not charging").
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int percent: 0
    property string status: "Unknown"

    Process {
        id: batProc
        command: ["bash", "-c", "for d in /sys/class/power_supply/BAT*; do [ -r \"$d/capacity\" ] || continue; read -r pct < \"$d/capacity\"; read -r st < \"$d/status\"; printf 'BAT %s %s\\n' \"$pct\" \"$st\"; break; done"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var parts = line.trim().split(/\s+/);
                if (parts.length < 3 || parts[0] !== "BAT")
                    return;
                root.percent = parseInt(parts[1]) || 0;
                root.status = parts.slice(2).join(" ") || "Unknown";
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: batProc.running = true
    }
}
