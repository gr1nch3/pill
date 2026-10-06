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

    // Face-dance outputs: `bass` (smoothed low band, 0..1) lifts the face,
    // `pulse` (a decaying hit, 0..1) pops the pupils, `swing` (-1..1) flips
    // direction on each kick and decays between them, swaying and tilting the
    // face. Beat detection here — rather than a level — is what reads as
    // dancing instead of a VU meter.
    property real bass: 0
    property real pulse: 0
    property real swing: 0
    property real _swayTarget: 0
    property int _swayDir: 1
    property real _bassSlow: 0
    property double _lastOnset: 0

    // Set false by shell.qml while the bar is hidden — stops the cava process.
    property bool active: true

    Process {
        command: ["cava", "-p", Config.cavaConfig]
        running: root.active
        // cava gone (bar hidden, track stopped): don't leave a frozen face.
        onRunningChanged: if (!running) {
            root.bars = [];
            root.bass = 0;
            root.pulse = 0;
            root.swing = 0;
        }
        stdout: SplitParser {
            onRead: function (line) {
                var vals = line.trim().split(";").filter(function (v) {
                    return v !== "";
                }).map(function (v) {
                    return parseFloat(v);
                }).filter(function (v) {
                    return isFinite(v);
                });
                if (vals.length === 0)
                    return;
                root.bars = vals;
                // Bounce follows a smoothed low band; the kick detector flips
                // the sway direction and fires the pupil pulse, then both
                // decay (~0.4 s pulse, ~1 s sway) so the face settles between
                // beats instead of jittering on every frame.
                var low = Math.min(1, (vals[0] / 100) * 1.4);
                root.bass += (low - root.bass) * 0.4;
                root._bassSlow += (low - root._bassSlow) * 0.04;
                var now = Date.now();
                if (low > 0.1 && low > root._bassSlow * 1.3 && now - root._lastOnset > 120) {
                    root._lastOnset = now;
                    root._swayDir = -root._swayDir;
                    root.pulse = Math.min(1, low * 1.5);
                    root._swayTarget = root._swayDir * Math.min(1, low * 1.5);
                }
                // Ease toward the flip instead of jumping: the target fades
                // between kicks and swing follows it, so the tilt rolls
                // through zero rather than snapping side to side.
                root._swayTarget *= 0.94;
                root.swing += (root._swayTarget - root.swing) * 0.22;
                root.pulse *= 0.9;
            }
        }
    }
}
