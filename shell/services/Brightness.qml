pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int percent: 0

    property int _lastPercent: -1

    signal changed

    Process {
        id: queryProc
        // machine-readable: device,class,current,percent%,max — parse the
        // percent field directly (no cut/baseline math).
        command: ["brightnessctl", "--machine-readable"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var parts = line.trim().split(",");
                if (parts.length < 5)
                    return;
                var pct = parseInt(parts[3]);
                if (isNaN(pct))
                    return;
                root.percent = pct;

                if (root._lastPercent !== -1 && pct !== root._lastPercent) {
                    root.changed();
                }
                root._lastPercent = pct;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: queryProc.running = true
    }

    function setPercent(pct) {
        pct = Math.max(0, Math.min(100, pct));
        setProc.command = ["brightnessctl", "set", pct + "%"];
        setProc.running = true;
        root.percent = pct;
    }

    function adjust(delta) {
        var pct = Math.max(0, Math.min(100, root.percent + delta));
        setPercent(pct);
    }

    Process {
        id: setProc
        command: []
        running: false
    }
}
