pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int percent: 0
    property string status: "Unknown"

    Process {
        id: batProc
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo 0"]
        running: true
        stdout: SplitParser {
            onRead: function(line) { root.percent = parseInt(line.trim()) || 0 }
        }
    }

    Process {
        id: statusProc
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo Unknown"]
        running: true
        stdout: SplitParser {
            onRead: function(line) { root.status = line.trim() || "Unknown" }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            batProc.running = true
            statusProc.running = true
        }
    }
}
