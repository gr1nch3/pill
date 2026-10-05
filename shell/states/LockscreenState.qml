import QtQuick
import QtQuick.Effects
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
    signal unlocked

    // ── Background: wallpaper (gifs animate, videos show their still) with a
    // dark scrim and the optional pattern overlay. ────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#FF000000"

        AnimatedImage {
            anchors.fill: parent
            visible: Config.lockWallpaper && Wallpaper.lockKind === "gif" && Wallpaper.lockTarget !== ""
            source: visible ? "file://" + Wallpaper.lockTarget : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Image {
            anchors.fill: parent
            visible: Config.lockWallpaper && Wallpaper.lockKind !== "gif" && Wallpaper.lockSource !== ""
            source: visible ? "file://" + Wallpaper.lockSource : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            color: "#A0000000"
        }

        PatternBackground {
            anchors.fill: parent
            visible: Config.lockPattern && Config.effectiveLockPatternStyle !== "none"
            variant: Config.effectiveLockPatternStyle
            spacing: Config.effectiveLockPatternDensity === "dense" ? 13 : (Config.effectiveLockPatternDensity === "sparse" ? 26 : 18)
            strength: 0.06
            color: Theme.accent
            shape: "rect"
        }
    }

    // ── Face: eyes above, pill below ─────────────────────────────────────
    readonly property real faceCenterY: height / 2
    readonly property bool faceOn: Config.eyesEnabled
    readonly property real eyesCenterY: root.faceCenterY - (root.faceOn ? 92 : 0)
    readonly property real pillCenterY: root.faceCenterY + (root.faceOn ? 52 : 0)

    EyeFace {
        id: lockEyes
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.eyesCenterY - height / 2
        eyeWidth: 96
        eyeHeight: 68
        eyeSpacing: 44
        baseMood: errorText.text !== "" ? "error" : (root.expanded ? "active" : "idle")
        beat: Playerctl.musicPlaying ? Cava.level : 0
    }

    // Single-pass shadow, same as the island pill.
    MultiEffect {
        source: pill
        anchors.fill: pill
        z: -1
        shadowEnabled: true
        shadowColor: "#80000000"
        shadowBlur: 0.7
        shadowVerticalOffset: 4
    }

    // ── Pill (compact clock, expands into the password input) ────────────
    Rectangle {
        id: pill

        // Bindings, not assignments: the parent height is 0 at creation, so
        // one-shot setters would freeze the pill at the wrong place.
        property real _targetW: root.expanded ? 360 : 240
        property real _targetH: root.expanded ? 92 : 72
        property real _targetY: root.pillCenterY - _targetH / 2

        width: _targetW
        height: _targetH
        color: "transparent"
        x: (parent.width - width) / 2
        y: _targetY

        readonly property real shapeRadius: root.expanded ? Theme.shape.radius.panel : _targetH * 0.5

        SurfaceShape {
            anchors.fill: parent
            shape: Theme.shape.style
            slant: Theme.shape.slant
            radius: pill.shapeRadius
            color: Theme.surface
            borderColor: Theme.border
            borderWidth: Theme.shape.border.width
            Behavior on radius {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.0
                }
            }
        }

        Behavior on _targetW {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1.0
            }
        }
        Behavior on _targetH {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1.0
            }
        }
        Behavior on _targetY {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1.0
            }
        }

        // ── Compact: time + lock icon ───────────────────────────────────
        Item {
            anchors.fill: parent
            anchors.margins: 3
            opacity: !root.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                CompactClock {
                    anchors.verticalCenter: parent.verticalCenter
                    fontSize: Theme.font.size.xlarge
                    ampmFontSize: Theme.font.size.small
                    fontWeight: 700
                    ampmBottomMargin: 2
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.lock
                    font.pixelSize: Theme.font.size.xlarge
                    font.family: Theme.font.mono
                    color: Theme.accent
                }
            }
        }

        // ── Expanded: password input (Enter submits) ─────────────────────
        Item {
            anchors.fill: parent
            anchors.margins: root.expanded ? 24 : 0
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.motion.panel
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on anchors.margins {
                NumberAnimation {
                    duration: Theme.motion.panel
                }
            }

            Row {
                anchors.centerIn: parent
                width: parent.width
                height: 44
                spacing: 10

                SurfaceShape {
                    shape: Theme.shape.style
                    slant: Theme.shape.slant
                    width: parent.width
                    height: parent.height
                    radius: Theme.shape.radius.row
                    color: Theme.background
                    borderWidth: Theme.shape.border.width
                    borderColor: passwordField.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        anchors.margins: 12
                        color: Theme.text
                        font.pixelSize: Theme.font.size.normal
                        font.family: Theme.font.family
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        onAccepted: submit()
                        Keys.onEscapePressed: {
                            if (passwordField.text === "")
                                root.expanded = false;
                            else
                                passwordField.text = "";
                        }
                    }
                }
            }
        }
    }

    // ── Error text (below the face) ──────────────────────────────────────
    Text {
        id: errorText
        anchors.horizontalCenter: parent.horizontalCenter
        y: pill.y + pill.height + 12
        visible: text !== ""
        color: Theme.danger
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    // ── Hint text ────────────────────────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: pill.y + pill.height + 24
        text: "Press any key to unlock"
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        opacity: !root.expanded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.motion.panel
            }
        }
        SequentialAnimation on opacity {
            running: !root.expanded
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.4
                duration: 2000
            }
            NumberAnimation {
                to: 1.0
                duration: 2000
            }
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
            if (!responseRequired)
                return;
            respond(root._buffer);
            root._buffer = "";
        }

        onCompleted: res => {
            root._authInFlight = false;
            if (res !== PamResult.Success) {
                errorText.text = "Authentication failed";
                passwordField.text = "";
                passwordField.forceActiveFocus();
                return;
            }

            root.expanded = false;
            unlockTimer.start();
        }

        onError: err => {
            root._authInFlight = false;
            errorText.text = "Authentication error: " + PamError.toString(err);
            passwordField.text = "";
        }
    }

    function submit() {
        if (passwordField.text === "" || root._authInFlight)
            return;
        errorText.text = "";
        root._authInFlight = true;
        root._buffer = passwordField.text;
        if (!pam.start()) {
            root._authInFlight = false;
            errorText.text = "Failed to start authentication";
            passwordField.text = "";
        }
    }

    // ── Keyboard ─────────────────────────────────────────────────────────
    focus: true
    Keys.onPressed: event => {
        if (!root.expanded) {
            root.expanded = true;
            event.accepted = true;
            Qt.callLater(function () {
                passwordField.forceActiveFocus();
            });
        }
    }
    Keys.onEscapePressed: {
        if (root.expanded) {
            root.expanded = false;
            passwordField.text = "";
            errorText.text = "";
            root.forceActiveFocus();
        }
    }
}
