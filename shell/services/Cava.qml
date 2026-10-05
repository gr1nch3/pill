pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property var bars: []

    // Mean amplitude 0..1 — the shared beat input for the eyes (PRD §6.4).
    readonly property real level: {
        if (!bars.length)
            return 0;
        var s = 0;
        for (var i = 0; i < bars.length; i++)
            s += bars[i];
        return Math.min(1, (s / bars.length) / 60);
    }

    // Set false by shell.qml while the bar is hidden — stops the cava process.
    property bool active: true

    Process {
        command: ["cava", "-p", Config.cavaConfig]
        running: root.active
        stdout: SplitParser {
            onRead: function (line) {
                var vals = line.trim().split(";").filter(function (v) {
                    return v !== "";
                }).map(function (v) {
                    return parseFloat(v);
                });
                if (vals.length > 0)
                    root.bars = vals;
            }
        }
    }
}
