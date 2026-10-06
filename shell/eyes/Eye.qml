// Bubbles visual identity: a pair of procedurally animated robot eyes.
// Pure QtQuick — no Quickshell imports — so the SDDM greeter process can
// reuse this file verbatim (PRD §5.3).
//
// Flat line-art only: Rectangles on the scene graph, no Canvas, no
// ShaderEffect blur/glow (PRD §9.2). All Timers stop when the item is not
// visible or its owner says animations are paused, so a hidden bar or an
// inactive settings page costs nothing.

// Versioned QtQuick 2.15: this file is copied verbatim into the SDDM greeter,
// whose X11 process is the Qt 5.15 build. No Qt6-only QML here.
import QtQuick 2.15

Item {
    id: root

    // ── Geometry ────────────────────────────────────────────────────────────
    property real eyeWidth: 26
    property real eyeHeight: 18
    property real eyeSpacing: 12
    implicitWidth: eyeWidth * 2 + eyeSpacing
    implicitHeight: eyeHeight

    // ── Behaviour ───────────────────────────────────────────────────────────
    // When true, both pupils aim at `target` (in root coordinates).
    // Otherwise they drift idly.
    property bool trackCursor: false
    property point target: Qt.point(-1, -1)

    // Degrees. Control center glances at its toggle row (§6.4): set a few
    // degrees while positioned left of the content. Sign flips the glance
    // direction — prototype both before locking one in.
    property real slant: 0

    // idle | active | alert | error — primary state-communication channel.
    property string mood: "idle"

    // Expression shape: normal | angry | sad | surprised | sleepy.
    // Geometry-only (no extra assets) so SDDM's verbatim copy stays valid.
    property string variant: "normal"

    // Media beat-sync input (§6.4): 0..1, a decaying hit per kick — the
    // pupils pop with it. EyeFace feeds it Cava.pulse on every dancing face.
    property real beat: 0

    // Music-dance inputs (EyeFace wires these from Cava): dance = 0..1
    // low-band energy, lifts the face on the beat; swing = -1..1, sways and
    // tilts it side to side. Defaults keep a standalone face (SDDM greeter)
    // perfectly still.
    property real dance: 0
    property real swing: 0

    // QML `visible` is local, so an eye inside a hidden state pane or an
    // inactive settings page would keep drifting/blinking. Owners that know
    // better (EyeFace) pause the idle timers with this flag; the greeter's
    // verbatim copy never sets it and keeps the default.
    property bool animationsActive: true

    // Mood → look. Overridable per theme; defaults are theme-neutral.
    property var moods: ({
            idle: {
                color: "#8a93a6",
                opacity: 0.55
            },
            active: {
                color: "#e6ecf7",
                opacity: 1.0
            },
            alert: {
                color: "#f0a500",
                opacity: 1.0
            },
            error: {
                color: "#e5484d",
                opacity: 1.0
            }
        })

    readonly property var _look: moods[mood] ?? moods.idle
    // Convert the JS colour string to a real colour once; `.r/.g/.b` on the
    // raw string are undefined and Qt.rgba() would produce black.
    readonly property color _lookColor: _look.color

    // ── Internals ───────────────────────────────────────────────────────────
    readonly property real _maxOffset: eyeWidth * 0.22
    property point _drift: Qt.point(0, 0)
    property real _blink: 1   // 1 open, ~0.08 shut
    // Momentary startle 0..1: pupils pop and the pair lifts, then settles.
    // Driven by EyeReactions in the shell; the greeter's verbatim copy simply
    // never calls react().
    property real _react: 0
    // Momentary glance, signed -1..1, added to the idle drift. Used for
    // workspace switches and other "look that way" moments.
    property real _glance: 0
    property real _glanceDir: 1
    // Sleepy: pupils sit lower, under the heavy lid, and barely wander.
    readonly property real _variantOffsetY: root.variant === "sleepy" ? root.eyeHeight * 0.26 : 0
    readonly property real _lidY: root.eyeHeight * 0.55

    function react() {
        reactAnim.restart();
    }
    function blink() {
        blinkAnim.restart();
    }
    function glance(dir) {
        root._glanceDir = dir >= 0 ? 1 : -1;
        glanceAnim.restart();
    }

    Item {
        anchors.centerIn: parent
        width: root.width
        height: root.height
        rotation: root.slant + root.swing * 6
        transform: Translate {
            // Cap the travel so a big face (lock screen) sways, not lurches.
            x: root.swing * Math.min(root.eyeWidth * 0.25, 10)
            y: -root._react * 2 - root.dance * (root.eyeHeight * 0.5 + 1)
        }

        Row {
            spacing: root.eyeSpacing

            Repeater {
                model: 2

                Item {
                    width: root.eyeWidth
                    height: root.eyeHeight

                    transform: Scale {
                        yScale: root._blink
                        origin.y: root.eyeHeight / 2
                    }

                    // Socket: flat rounded rect, line-art border.
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Qt.rgba(root._lookColor.r, root._lookColor.g, root._lookColor.b, 0.08 * root._look.opacity)
                        border.color: root._look.color
                        border.width: 2
                        opacity: root._look.opacity

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 250
                            }
                        }
                    }

                    // Pupil.
                    Rectangle {
                        property point offset: root._pupilOffset(index)

                        x: (parent.width - width) / 2 + offset.x
                        y: root.variant === "sleepy" ? Math.max(root._lidY - height * 0.2, (parent.height - height) / 2 + offset.y + root._variantOffsetY) : (parent.height - height) / 2 + offset.y
                        width: root.eyeHeight * 0.42 * (1 + root.beat * 0.6 + root._react * 0.30) * (root.variant === "surprised" ? 0.78 : 1)
                        height: width
                        radius: width / 2
                        color: root._look.color
                        opacity: root._look.opacity

                        Behavior on x {
                            NumberAnimation {
                                duration: 350
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on y {
                            NumberAnimation {
                                duration: 350
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 250
                            }
                        }
                    }

                    // Heavy eyelid for sleepy: shade the top of the socket.
                    // The lid is a full capsule clipped to the top 55% — same
                    // shape as per-corner radii, but pure Rectangle/Item so
                    // Qt 5.15 (the greeter's engine) can load it. Drawn over
                    // the pupil so the lid tints its top.
                    Item {
                        visible: root.variant === "sleepy"
                        width: root.eyeWidth
                        height: root._lidY
                        clip: true

                        Rectangle {
                            width: root.eyeWidth
                            height: root.eyeHeight
                            radius: root.eyeHeight / 2
                            color: Qt.rgba(root._lookColor.r, root._lookColor.g, root._lookColor.b, 0.22 * root._look.opacity)
                        }
                    }

                    // Expression lid / brow: a line-art stroke over the socket.
                    Rectangle {
                        id: lid
                        visible: root.variant !== "normal"
                        width: root.eyeWidth * (root.variant === "sleepy" ? 1.0 : 0.9)
                        height: 2.5
                        radius: 1.25
                        color: root._look.color
                        opacity: root._look.opacity * 0.95
                        x: (parent.width - width) / 2
                        y: root.variant === "sleepy" ? root.eyeHeight * 0.55 - height / 2 : (root.variant === "surprised" ? -7 : -4)
                        rotation: {
                            var a = root.variant === "angry" ? 18 : (root.variant === "sad" ? -18 : 0);
                            return index === 0 ? a : -a;
                        }

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on y {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }

    function _pupilOffset(eyeIndex) {
        if (trackCursor && target.x >= 0) {
            // Aim at target from this eye's centre, clamped.
            var cx = eyeIndex * (eyeWidth + eyeSpacing) + eyeWidth / 2;
            var cy = eyeHeight / 2;
            var dx = target.x - cx;
            var dy = target.y - cy;
            var len = Math.max(0.001, Math.sqrt(dx * dx + dy * dy));
            var k = Math.min(1, len / (width / 2)) * _maxOffset;
            return Qt.point(dx / len * k, dy / len * k);
        }
        return Qt.point(_drift.x + _glance * _maxOffset, _drift.y);
    }

    // Idle drift: pick a new resting offset every couple of seconds.
    Timer {
        interval: 2200
        running: root.visible && root.animationsActive
        repeat: true
        onTriggered: {
            var a = Math.random() * Math.PI * 2;
            var r = Math.random() * root._maxOffset;
            root._drift = Qt.point(Math.cos(a) * r, Math.sin(a) * r * 0.5);
        }
    }

    // Blink: jittered 4–8 s interval, never a metronome (§6.3).
    Timer {
        interval: 4000 + Math.random() * 4000
        running: root.visible && root.animationsActive
        repeat: true
        onTriggered: {
            interval = 4000 + Math.random() * 4000;
            blinkAnim.restart();
        }
    }

    SequentialAnimation {
        id: blinkAnim
        NumberAnimation {
            target: root
            property: "_blink"
            to: 0.08
            duration: 70
        }
        PauseAnimation {
            duration: 60
        }
        NumberAnimation {
            target: root
            property: "_blink"
            to: 1
            duration: 90
        }
    }

    // Startle: quick pop, soft settle. restart() is safe to spam — a new
    // reaction just re-catches the eye mid-air.
    SequentialAnimation {
        id: reactAnim
        NumberAnimation {
            target: root
            property: "_react"
            to: 1
            duration: 110
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "_react"
            to: 0
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    // Glance: dart sideways, hold, come back.
    SequentialAnimation {
        id: glanceAnim
        NumberAnimation {
            target: root
            property: "_glance"
            to: root._glanceDir
            duration: 90
            easing.type: Easing.OutQuad
        }
        PauseAnimation {
            duration: 260
        }
        NumberAnimation {
            target: root
            property: "_glance"
            to: 0
            duration: 240
            easing.type: Easing.OutCubic
        }
    }
}
