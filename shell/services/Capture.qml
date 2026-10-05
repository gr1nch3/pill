pragma Singleton
// Capture state machine: screenshots and recordings. Views bind to `view`
// and call the verbs; command construction stays in Integrations.
import QtQuick

import "../utils"

Item {
    id: root

    property string view: "grid"          // grid | destination | result | recording
    property string mode: "region"        // screenshot mode
    property string path: ""              // last screenshot
    property bool recording: false
    property bool paused: false
    property string elapsed: "00:00"
    property var startTime: null

    readonly property real viewWidth: view === "recording" ? 280 : 420
    readonly property real viewHeight: {
        if (view === "grid")
            return 250;
        if (view === "destination")
            return 150;
        if (view === "result")
            return 140;
        if (view === "recording")
            return 64;
        return 280;
    }

    // The island must close before slurp/grim: its fullscreen dismiss overlay
    // would swallow the pointer events region picking needs.
    signal dismissRequested
    signal saved(string path)

    property string _pendingDest: ""
    property string _pendingPath: ""
    property string _recordingPath: ""

    function selectMode(m) {
        mode = m;
        view = "destination";
    }

    function startShot(dest) {
        if (!Integrations.canScreenshot)
            return;
        var ts = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
        var filepath = Config.screenshotDir + "/screenshot_" + ts + ".png";
        _pendingDest = dest;
        _pendingPath = filepath;
        dismissRequested();
        shotCmd.command = Integrations.shotCommand(mode, dest, filepath);
        shotCmd.run();
    }

    function startFullscreenRecording() {
        _startRecording("");
    }

    function startRegionRecording() {
        if (!Integrations.canRecord || !Integrations.canRegion)
            return;
        geoCmd.command = Integrations.regionPickerCommand;
        geoCmd.run();
    }

    function _startRecording(geometry) {
        if (!Integrations.canRecord)
            return;
        var ts = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
        root._recordingPath = Config.recordingDir + "/recording_" + ts + ".mp4";
        recorderCmd.command = Integrations.recordingCommand(geometry, root._recordingPath);
        recorderCmd.run();
        recording = true;
        startTime = new Date();
        view = "recording";
    }

    function togglePause() {
        if (!Integrations.canRecord)
            return;
        stopRecorderCmd.command = Integrations.recordPauseCommand;
        stopRecorderCmd.run();
        paused = !paused;
    }

    function stopRecording() {
        if (Integrations.canRecord) {
            stopRecorderCmd.command = Integrations.recordStopCommand;
            stopRecorderCmd.run();
        }
        recording = false;
        paused = false;
        dismissRequested();
    }

    // ── Post-screenshot actions ──
    function resultOpen() {
        if (!path)
            return;
        actionCmd.command = ["xdg-open", path];
        actionCmd.run();
    }

    function resultEdit() {
        if (!path || !Integrations.canAnnotate)
            return;
        actionCmd.command = Integrations.annotateCommand(path);
        actionCmd.run();
    }

    function resultCopy() {
        if (!path)
            return;
        actionCmd.command = Integrations.copyCommand(path);
        actionCmd.run();
    }

    function resultDelete() {
        if (!path)
            return;
        actionCmd.command = ["rm", path];
        actionCmd.run();
        path = "";
        view = "grid";
    }

    function resultShowInFolder() {
        if (!path)
            return;
        var dir = path.substring(0, path.lastIndexOf("/"));
        actionCmd.command = ["xdg-open", dir];
        actionCmd.run();
    }

    // ── Adapters ──
    Cmd {
        id: shotCmd
        autorun: false
        onDone: function (code) {
            var dest = root._pendingDest;
            root._pendingDest = "";
            // Slurp cancelled or grim failed: stay idle, no bogus result view.
            if (code !== 0 || dest === "clipboard")
                return;
            root.path = root._pendingPath;
            root.view = "result";
            root.saved(root.path);
        }
    }

    Cmd {
        id: recorderCmd
        autorun: false
    }
    Cmd {
        id: stopRecorderCmd
        autorun: false
    }
    Cmd {
        id: actionCmd
        autorun: false
    }

    Cmd {
        id: geoCmd
        autorun: false
        onLine: function (line) {
            line = line.trim();
            if (!line)
                return;
            root._startRecording(line);
        }
    }

    Timer {
        interval: 1000
        running: root.recording
        repeat: true
        onTriggered: {
            if (!root.startTime)
                return;
            var ms = new Date().valueOf() - root.startTime.valueOf();
            var seconds = Math.floor(ms / 1000);
            var h = Math.floor(seconds / 3600);
            var m = Math.floor((seconds % 3600) / 60);
            var s = seconds % 60;
            root.elapsed = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
        }
    }
}
