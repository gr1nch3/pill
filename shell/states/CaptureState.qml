import QtQuick

import "../services"
import "../components"
import "../utils"
import "../eyes"

StatePane {
    id: root
    stateName: "capture"
    keyboardFocus: true
    preferredWidth: Capture.viewWidth
    preferredHeight: Capture.viewHeight

    anchors.fill: parent

    Connections {
        target: Capture
        function onDismissRequested() { IslandState.closeToIdle() }
        function onSaved(path) { IslandState.open("capture") }
    }

    // Models react to tool availability (Integrations probes at startup).
    readonly property var shotModeModel: {
        var m = []
        if (Integrations.canScreenshot) {
            if (Integrations.canRegion) {
                m.push({ icon: Icons.screenshotRegion, label: "Region", mode: "region" })
                m.push({ icon: Icons.screenshotWindow, label: "Window", mode: "window" })
            }
            m.push({ icon: Icons.screenshotOutput, label: "Fullscreen", mode: "output" })
        }
        return m
    }

    readonly property var recordModel: {
        var m = []
        if (Integrations.canRecord) {
            m.push({ icon: Icons.recStart, label: "Fullscreen", action: Capture.startFullscreenRecording })
            if (Integrations.canRegion)
                m.push({ icon: Icons.screenshotRegion, label: "Region", action: Capture.startRegionRecording })
        }
        return m
    }

    readonly property var destinationModel: {
        var m = [{ icon: Icons.captureSave, label: "Save", dest: "save" }]
        if (Integrations.canCopy) {
            m.push({ icon: Icons.captureCopy, label: "Copy", dest: "clipboard" })
            m.push({ icon: Icons.saveCopy, label: "Save & Copy", dest: "both" })
        }
        return m
    }

    readonly property var resultModel: {
        var m = [{ icon: Icons.captureOpen, label: "Open", action: Capture.resultOpen }]
        if (Integrations.canAnnotate)
            m.push({ icon: Icons.captureEdit, label: "Edit", action: Capture.resultEdit })
        if (Integrations.canCopy)
            m.push({ icon: Icons.captureCopy, label: "Copy", action: Capture.resultCopy })
        m.push({ icon: Icons.captureDelete, label: "Delete", action: Capture.resultDelete })
        m.push({ icon: Icons.captureFolder, label: "Show in folder", action: Capture.resultShowInFolder })
        return m
    }

    // ── Grid view (step 1: select mode) ────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        visible: Capture.view === "grid"
        opacity: Capture.view === "grid" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motion.panel; easing.type: Easing.OutCubic } }

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
                model: root.shotModeModel

                CaptureTile {
                    required property var modelData

                    width: (parent.width - 16) / 3
                    height: 72
                    icon: modelData.icon
                    label: modelData.label
                    onClicked: Capture.selectMode(modelData.mode)
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
                model: root.recordModel

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

        Text {
            visible: root.shotModeModel.length === 0 && root.recordModel.length === 0
            width: parent.width
            text: "No capture tools found — install grim, slurp and wf-recorder (see Settings → Integrations)."
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            wrapMode: Text.WordWrap
        }
    }

    // ── Destination view (step 2: save / copy / both) ─────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        visible: Capture.view === "destination"
        opacity: Capture.view === "destination" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motion.panel; easing.type: Easing.OutCubic } }

        Row {
            width: parent.width
            spacing: 10
            BackButton { anchors.verticalCenter: parent.verticalCenter; onClicked: Capture.view = "grid" }
            EyeFace {
                width: 2 * eyeWidth + eyeSpacing; height: eyeHeight
                eyeWidth: 18; eyeHeight: 13; eyeSpacing: 7
                anchors.verticalCenter: parent.verticalCenter
                mood: Capture.recording ? "error" : "active"
            }
            Text {
                text: {
                    var m = Capture.mode
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
                model: root.destinationModel

                CaptureTile {
                    required property var modelData

                    width: (parent.width - 16) / 3
                    height: 72
                    icon: modelData.icon
                    label: modelData.label
                    iconColor: Theme.accent
                    onClicked: Capture.startShot(modelData.dest)
                }
            }
        }
    }

    // ── Result view (post-screenshot) ─────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        visible: Capture.view === "result"
        opacity: Capture.view === "result" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motion.panel; easing.type: Easing.OutCubic } }

        Row {
            width: parent.width
            spacing: 10
            BackButton { anchors.verticalCenter: parent.verticalCenter; onClicked: Capture.view = "grid" }
            EyeFace {
                width: 2 * eyeWidth + eyeSpacing; height: eyeHeight
                eyeWidth: 18; eyeHeight: 13; eyeSpacing: 7
                anchors.verticalCenter: parent.verticalCenter
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
            text: Capture.path
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
                model: root.resultModel

                CaptureTile {
                    required property var modelData

                    width: (parent.width - (root.resultModel.length - 1) * 8) / root.resultModel.length
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
        visible: Capture.view === "recording"
        opacity: Capture.view === "recording" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motion.panel; easing.type: Easing.OutCubic } }

        Rectangle {
            width: 44; height: 44; radius: Theme.shape.radius.cardLarge
            color: recPauseHover.containsMouse ? Theme.surfaceHover : Theme.background
            Behavior on color { ColorAnimation { duration: Theme.motion.normal } }
            Text {
                anchors.centerIn: parent
                text: Capture.paused ? Icons.recStart : Icons.pause
                font.pixelSize: Theme.font.size.xlarge
                font.family: Theme.font.mono
                color: Theme.accent
            }
            MouseArea {
                id: recPauseHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Capture.togglePause()
            }
        }

        Rectangle {
            width: 44; height: 44; radius: Theme.shape.radius.cardLarge
            color: recStopHover.containsMouse ? Theme.dangerHover : Theme.dangerBg
            Behavior on color { ColorAnimation { duration: Theme.motion.normal } }
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
                onClicked: Capture.stopRecording()
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: Capture.paused ? "paused" : "recording " + Capture.elapsed
                color: Capture.paused ? Theme.subtext : Theme.danger
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
                font.weight: 500
            }
            Text {
                text: Capture.paused ? "resume or stop" : "click to stop"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.family
            }
        }
    }
}
