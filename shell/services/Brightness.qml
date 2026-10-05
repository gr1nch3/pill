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
        command: ["bash", "-c", "brightnessctl --machine-readable | cut -d, -f3,5"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                var nums = line.trim().split(",");
                if (nums.length !== 2)
                    return;
                var cur = parseInt(nums[0]);
                var max = parseInt(nums[1]);
                if (isNaN(cur) || isNaN(max) || max <= 0)
                    return;
                var pct = Math.round((cur / max) * 100);
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
