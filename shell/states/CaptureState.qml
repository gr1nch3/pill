import QtQuick
import Quickshell.Io

import "../services"
import "../components"
import "../utils"
import "../utils/shquote.js" as Sh
import "../eyes"

Item {
    id: root

    anchors.fill: parent

    opacity: IslandState.state === "capture" ? 1 : 0
    visible: opacity > 0
    focus: visible
    Keys.onEscapePressed: IslandState.closeToIdle()
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Process { id: shotProc; command: []; running: false }
    Process { id: recorderProc; command: []; running: false }
    Process { id: stopRecorderProc; command: []; running: false }
    Process { id: actionProc; command: []; running: false }

    Process {
        id: geoProc
        command: []
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                line = line.trim()
                if (!line) return
                root._startRecording(line)
            }
        }
    }

    Timer {
        interval: 1000
        running: IslandState.recording
        repeat: true
        onTriggered: {
            if (!IslandState.recordingStartTime) return
            var elapsed = new Date().valueOf() - IslandState.recordingStartTime.valueOf()
            var seconds = Math.floor(elapsed / 1000)
            var h = Math.floor(seconds / 3600)
            var m = Math.floor((seconds % 3600) / 60)
            var s = seconds % 60
            IslandState.recordingElapsed =
                (h < 10 ? "0" : "") + h + ":" +
                (m < 10 ? "0" : "") + m + ":" +
                (s < 10 ? "0" : "") + s
        }
    }

    readonly property real captureWidth: {
        if (IslandState.captureView === "grid") return 420
        if (IslandState.captureView === "destination") return 420
        if (IslandState.captureView === "result") return 420
        if (IslandState.captureView === "recording") return 280
        return 420
    }
    readonly property real captureHeight: {
        if (IslandState.captureView === "grid") return 250
        if (IslandState.captureView === "destination") return 150
        if (IslandState.captureView === "result") return 140
        if (IslandState.captureView === "recording") return 64
        return 280
    }

    function _ensureDir() {
        actionProc.command = ["mkdir", "-p", Config.recordingDir, Config.screenshotDir]
        actionProc.running = true
    }

    function _startRecording(geometry) {
        var ts = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss")
        IslandState.recordingPath = Config.recordingDir + "/recording_" + ts + ".mp4"
        recorderProc.running = false
        recorderProc.command = ["wf-recorder", "-g", geometry, "-f", IslandState.recordingPath]
        recorderProc.running = true
        IslandState.recording = true
        IslandState.recordingStartTime = new Date()
        IslandState.captureView = "recording"
    }

    // ── Screenshot (grim + slurp; no compositor-specific tools) ──
    function selectScreenshotMode(mode) {
        IslandState.screenshotMode = mode
        IslandState.captureView = "destination"
    }

    function handleDestination(dest) {
        var mode = IslandState.screenshotMode
        var ts = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss")
        var filename = "screenshot_" + ts + ".png"
        var filepath = Config.screenshotDir + "/" + filename
        var qpath = Sh.q(filepath)

        root._ensureDir()

        // Fullscreen ("output") needs no region pick; region/window go via slurp.
        var src = (mode === "output") ? "" : "-g \"$(slurp)\" "

        if (dest === "clipboard") {
            shotProc.command = ["sh", "-c", "grim " + src + "- | wl-copy"]
            shotProc.running = true
            IslandState.closeToIdle()
            return
        }

        IslandState.capturedPath = filepath

        if (dest === "save") {
            shotProc.command = ["sh", "-c", "grim " + src + qpath]
        } else {
            shotProc.command = ["sh", "-c", "grim " + src + qpath + " && wl-copy < " + qpath]
        }
        shotProc.running = true
        IslandState.captureView = "result"
    }

    // ── Recording ──
    function startFullscreenRecording() {
        root._ensureDir()
        var ts = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss")
        IslandState.recordingPath = Config.recordingDir + "/recording_" + ts + ".mp4"
        recorderProc.running = false
        recorderProc.command = ["wf-recorder", "-f", IslandState.recordingPath]
        recorderProc.running = true
        IslandState.recording = true
        IslandState.recordingStartTime = new Date()
        IslandState.captureView = "recording"
    }

    function startRegionRecording() {
        root._ensureDir()
        geoProc.running = false
        geoProc.command = ["slurp"]
        geoProc.running = true
    }

    function togglePause() {
        stopRecorderProc.running = false
        stopRecorderProc.command = ["pkill", "-SIGUSR1", "wf-recorder"]
        stopRecorderProc.running = true
        IslandState.recordingPaused = !IslandState.recordingPaused
    }

    function stopRecording() {
        stopRecorderProc.running = false
        stopRecorderProc.command = ["pkill", "-SIGINT", "wf-recorder"]
        stopRecorderProc.running = true
        IslandState.recording = false
        IslandState.recordingPaused = false
        IslandState.closeToIdle()
    }

    // ── Post-screenshot actions ──
    function resultOpen() {
        if (!IslandState.capturedPath) return
        actionProc.command = ["xdg-open", IslandState.capturedPath]
        actionProc.running = true
    }
    function resultEdit() {
        if (!IslandState.capturedPath) return
        actionProc.command = ["swappy", "-f", IslandState.capturedPath]
        actionProc.running = true
    }
    function resultCopy() {
        if (!IslandState.capturedPath) return
        actionProc.command = ["sh", "-c", "wl-copy < " + Sh.q(IslandState.capturedPath)]
        actionProc.running = true
    }
    function resultDelete() {
        if (!IslandState.capturedPath) return
        actionProc.command = ["rm", IslandState.capturedPath]
        actionProc.running = true
        IslandState.capturedPath = ""
        IslandState.captureView = "grid"
    }
    function resultShowInFolder() {
        if (!IslandState.capturedPath) return
        var dir = IslandState.capturedPath.substring(0, IslandState.capturedPath.lastIndexOf("/"))
        actionProc.command = ["xdg-open", dir]
        actionProc.running = true
    }

    // ── Grid view (step 1: select mode) ────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        visible: IslandState.captureView === "grid"
        opacity: IslandState.captureView === "grid" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Row {
            width: parent.width
            spacing: 10
            Text {
                text: "Screenshot & Recording"
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            text: "Screenshot"
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
        }

        Grid {
            width: parent.width
            columns: 3
            spacing: 8

            Repeater {
                model: [
                    { icon: Icons.screenshotRegion, label: "Region", mode: "region" },
                    { icon: Icons.screenshotWindow, label: "Window", mode: "window" },
                    { icon: Icons.screenshotOutput, label: "Fullscreen", mode: "output" }
                ]

                CaptureTile {
                    required property var modelData

                    width: (parent.width - 16) / 3
                    height: 72
                    icon: modelData.icon
                    label: modelData.label
                    onClicked: root.selectScreenshotMode(modelData.mode)
                }
            }
        }

        Text {
            text: "Recording"
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
        }

        Grid {
            width: parent.width
            columns: 3
            spacing: 8

            Repeater {
                model: [
                    { icon: Icons.recStart, label: "Fullscreen", action: root.startFullscreenRecording },
                    { icon: Icons.screenshotRegion, label: "Region", action: root.startRegionRecording }
                ]

                CaptureTile {
                    required property var modelData

                    width: (parent.width - 16) / 3
                    height: 72
                    icon: modelData.icon
                    label: modelData.label
                    iconColor: Theme.danger
                    onClicked: modelData.action()
                }
            }
        }
    }

    // ── Destination view (step 2: save / copy / both) ─────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        visible: IslandState.captureView === "destination"
        opacity: IslandState.captureView === "destination" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Row {
            width: parent.width
            spacing: 10
            BackButton { anchors.verticalCenter: parent.verticalCenter; onClicked: IslandState.captureView = "grid" }
            Eye {
                eyeWidth: 18; eyeHeight: 13; eyeSpacing: 7
                anchors.verticalCenter: parent.verticalCenter
                moods: Theme.eyeMoods
                mood: IslandState.recording ? "error" : "active"
            }
            Text {
                text: {
                    var m = IslandState.screenshotMode
                    if (m === "region") return "Region"
                    if (m === "window") return "Window"
                    return "Fullscreen"
                }
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            text: "Choose output method"
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
        }

        Grid {
            width: parent.width
            columns: 3
            spacing: 8

            Repeater {
                model: [
                    { icon: Icons.captureSave, label: "Save", dest: "save" },
                    { icon: Icons.captureCopy, label: "Copy", dest: "clipboard" },
                    { icon: Icons.saveCopy,    label: "Save & Copy", dest: "both" }
                ]

                CaptureTile {
                    required property var modelData

                    width: (parent.width - 16) / 3
                    height: 72
                    icon: modelData.icon
                    label: modelData.label
                    iconColor: Theme.accent
                    onClicked: root.handleDestination(modelData.dest)
                }
            }
        }
    }

    // ── Result view (post-screenshot) ─────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        visible: IslandState.captureView === "result"
        opacity: IslandState.captureView === "result" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Row {
            width: parent.width
            spacing: 10
            BackButton { anchors.verticalCenter: parent.verticalCenter; onClicked: IslandState.captureView = "grid" }
            Eye {
                eyeWidth: 18; eyeHeight: 13; eyeSpacing: 7
                anchors.verticalCenter: parent.verticalCenter
                moods: Theme.eyeMoods
                mood: "active"
            }
            Text {
                text: "Screenshot saved"
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            width: parent.width
            text: IslandState.capturedPath
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.mono
            elide: Text.ElideLeft
        }

        Row {
            width: parent.width
            spacing: 8
            height: 56

            Repeater {
                model: [
                    { icon: Icons.captureOpen,   label: "Open",          action: root.resultOpen },
                    { icon: Icons.captureEdit,   label: "Edit",          action: root.resultEdit },
                    { icon: Icons.captureCopy,   label: "Copy",          action: root.resultCopy },
                    { icon: Icons.captureDelete, label: "Delete",        action: root.resultDelete },
                    { icon: Icons.captureFolder, label: "Show in folder", action: root.resultShowInFolder }
                ]

                CaptureTile {
                    required property var modelData

                    width: (parent.width - 32) / 5
                    height: parent.height
                    cellRadius: 12
                    labelWeight: 500
                    icon: modelData.icon
                    label: modelData.label
                    onClicked: modelData.action()
                }
            }
        }
    }

    // ── Recording management view ─────────────────────────────────────────────
    Row {
        anchors.centerIn: parent
        spacing: 12
        visible: IslandState.captureView === "recording"
        opacity: IslandState.captureView === "recording" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            width: 44; height: 44; radius: 14
            color: recPauseHover.containsMouse ? Theme.surfaceHover : Theme.background
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: IslandState.recordingPaused ? Icons.recStart : Icons.pause
                font.pixelSize: Theme.font.size.xlarge
                font.family: Theme.font.mono
                color: Theme.accent
            }
            MouseArea {
                id: recPauseHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePause()
            }
        }

        Rectangle {
            width: 44; height: 44; radius: 14
            color: recStopHover.containsMouse ? Theme.dangerHover : Theme.dangerBg
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: Icons.recStop
                font.pixelSize: Theme.font.size.xlarge
                font.family: Theme.font.mono
                color: Theme.danger
            }
            MouseArea {
                id: recStopHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stopRecording()
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: IslandState.recordingPaused ? "paused" : "recording " + IslandState.recordingElapsed
                color: IslandState.recordingPaused ? Theme.subtext : Theme.danger
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
                font.weight: 500
            }
            Text {
                text: IslandState.recordingPaused ? "resume or stop" : "click to stop"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.family
            }
        }
    }
}
