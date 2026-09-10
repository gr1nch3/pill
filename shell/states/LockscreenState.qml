import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Pam

import "../services"
import "../components"
import "../utils"
import "../eyes"

Item {
    id: root
    anchors.fill: parent

    property bool expanded: false
    onExpandedChanged: {
        if (expanded) pill._setExpandedTargets()
        else pill._setCompactTargets()
    }
    signal unlocked()

    property string clockTime: Qt.formatTime(new Date(), "HH:mm")
    property string clockDate: Qt.formatDate(new Date(), "ddd, MMM d")

    Timer {
        running: true; repeat: true; interval: 1000
        onTriggered: {
            var now = new Date()
            root.clockTime = Qt.formatTime(now, "HH:mm")
            root.clockDate = Qt.formatDate(now, "ddd, MMM d")
        }
    }

    // ── Background: opaque base + blurred wallpaper + dark overlay ───────
    Rectangle {
        anchors.fill: parent
        color: "#FF000000"

        Image {
            anchors.fill: parent
            source: Wallpaper.currentWallpaper ? "file://" + Wallpaper.currentWallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true

            layer.enabled: true
            layer.effect: FastBlur {
                radius: 64
                transparentBorder: true
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#A0000000"
        }
    }

    // ── Pill ─────────────────────────────────────────────────────────────
    Rectangle {
        id: pill

        property real _targetW: Playerctl.musicPlaying ? 140 : 90
        property real _targetH: 34
        property real _targetY: Config.position === "top" ? 12 : parent.height - 34 - 12
        property real _targetR: 17

        width: _targetW
        height: _targetH
        radius: _targetR
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        x: (parent.width - width) / 2
        y: _targetY

        function _setCompactTargets() {
            _targetW = Playerctl.musicPlaying ? 120 : 90
            _targetH = 34
            _targetY = Config.position === "top" ? 12 : parent.height - 34 - 12
            _targetR = 17
        }

        function _setExpandedTargets() {
            _targetW = 280
            _targetH = 80
            _targetY = (parent.height - 80) / 2
            _targetR = 24
        }

        onParentChanged: {
            if (parent) _setCompactTargets()
        }

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 4
            radius: 16
            samples: 33
            color: "#80000000"
        }

        Behavior on _targetW { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
        Behavior on _targetH { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
        Behavior on _targetR { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
        Behavior on _targetY { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }

        // ── Compact: cava + time + lock icon (matching idle pill) ────────
        Item {
            anchors.fill: parent
            anchors.margins: 3
            opacity: !root.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            Row {
                anchors.centerIn: parent
                spacing: 6

                Eye {
                    eyeWidth: 13; eyeHeight: 10; eyeSpacing: 5
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Playerctl.musicPlaying
                    moods: Theme.eyeMoods
                    mood: "active"
                    beat: Cava.level
                }

                CompactClock {
                    anchors.verticalCenter: parent.verticalCenter
                    fontSize: Theme.font.size.large
                    fontWeight: 600
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.lock
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.mono
                    color: Theme.accent
                }
            }
        }

        // ── Expanded: password input with inline arrow button ────────────
        Item {
            anchors.fill: parent
            anchors.margins: root.expanded ? 20 : 0
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on anchors.margins { NumberAnimation { duration: 200 } }

            Row {
                anchors.centerIn: parent
                width: parent.width
                height: 40
                spacing: 8

                Rectangle {
                    width: parent.width - 48
                    height: parent.height
                    radius: 10
                    color: Theme.background
                    border.width: 1
                    border.color: passwordField.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: passwordField
                        anchors.fill: parent; anchors.margins: 10
                        color: Theme.text
                        font.pixelSize: Theme.font.size.normal; font.family: Theme.font.family
                        echoMode: TextInput.Password; passwordCharacter: "●"
                        onAccepted: submit()
                        Keys.onEscapePressed: {
                            if (passwordField.text === "") root.expanded = false
                            else passwordField.text = ""
                        }
                    }
                }

                Rectangle {
                    width: 40; height: parent.height; radius: 10
                    color: passwordField.text !== "" ? Theme.accent : Theme.surfaceHover
                    opacity: passwordField.text !== "" ? 1 : 0.5

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: passwordField.text !== "" ? Theme.background : Theme.subtext
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.mono
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: submit()
                    }
                }
            }

            Text {
                id: errorText
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                color: Theme.danger
                font.pixelSize: Theme.font.size.small; font.family: Theme.font.family
                wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ── Hint text ────────────────────────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: pill.y + pill.height + 24
        text: "Press any key to unlock"
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small; font.family: Theme.font.family
        opacity: !root.expanded ? 1 : 0; visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        SequentialAnimation on opacity {
            running: !root.expanded; loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 2000 }
            NumberAnimation { to: 1.0; duration: 2000 }
        }
    }

    // ── Unlock transition delay ──────────────────────────────────────────
    Timer {
        id: unlockTimer
        interval: 600
        onTriggered: root.unlocked()
    }

    // ── PAM ──────────────────────────────────────────────────────────────
    property string _buffer: ""
    property bool _authInFlight: false

    PamContext {
        id: pam
        config: "passwd"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onResponseRequiredChanged: {
            if (!responseRequired) return
            respond(root._buffer)
            root._buffer = ""
        }

        onCompleted: res => {
            root._authInFlight = false
            if (res !== PamResult.Success) {
                errorText.text = "Authentication failed"
                passwordField.text = ""
                passwordField.forceActiveFocus()
                return
            }

            root.expanded = false
            unlockTimer.start()
        }

        onError: err => {
            root._authInFlight = false
            errorText.text = "Authentication error: " + PamError.toString(err)
            passwordField.text = ""
        }
    }

    function submit() {
        if (passwordField.text === "" || root._authInFlight) return
        errorText.text = ""
        root._authInFlight = true
        root._buffer = passwordField.text
        if (!pam.start()) {
            root._authInFlight = false
            errorText.text = "Failed to start authentication"
            passwordField.text = ""
        }
    }

    // ── Keyboard ─────────────────────────────────────────────────────────
    focus: true
    Keys.onPressed: event => {
        if (!root.expanded) {
            root.expanded = true
            event.accepted = true
            Qt.callLater(function() { passwordField.forceActiveFocus() })
        }
    }
    Keys.onEscapePressed: {
        if (root.expanded) {
            root.expanded = false
            passwordField.text = ""
            errorText.text = ""
            root.forceActiveFocus()
        }
    }
}
