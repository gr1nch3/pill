// Bubbles visual identity: a pair of procedurally animated robot eyes.
// Pure QtQuick — no Quickshell imports — so the SDDM greeter process can
// reuse this file verbatim (PRD §5.3).
//
// Flat line-art only: Rectangles on the scene graph, no Canvas, no
// ShaderEffect blur/glow (PRD §9.2). All Timers stop when the item is not
// visible, so a hidden bar costs nothing.

import QtQuick

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

    // Media beat-sync input (§6.4): 0..1 amplitude, consumer binds it to
    // Cava data. Scales the pupils so the eyes "pulse" with the track.
    property real beat: 0

    // Mood → look. Overridable per theme; defaults are theme-neutral.
    property var moods: ({
        idle:   { color: "#8a93a6", opacity: 0.55 },
        active: { color: "#e6ecf7", opacity: 1.0 },
        alert:  { color: "#f0a500", opacity: 1.0 },
        error:  { color: "#e5484d", opacity: 1.0 }
    })

    readonly property var _look: moods[mood] ?? moods.idle

    // ── Internals ───────────────────────────────────────────────────────────
    readonly property real _maxOffset: eyeWidth * 0.22
    property point _drift: Qt.point(0, 0)
    property real _blink: 1   // 1 open, ~0.08 shut

    Item {
        anchors.centerIn: parent
        width: root.width
        height: root.height
        rotation: root.slant

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
                        color: Qt.rgba(root._look.color.r, root._look.color.g, root._look.color.b, 0.08 * root._look.opacity)
                        border.color: root._look.color
                        border.width: 2
                        opacity: root._look.opacity

                        Behavior on border.color { ColorAnimation { duration: 250 } }
                    }

                    // Pupil.
                    Rectangle {
                        property point offset: root._pupilOffset(index)

                        x: (parent.width - width) / 2 + offset.x
                        y: (parent.height - height) / 2 + offset.y
                        width: root.eyeHeight * 0.42 * (1 + root.beat * 0.35)
                        height: width
                        radius: width / 2
                        color: root._look.color
                        opacity: root._look.opacity

                        Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                }
            }
        }
    }

    function _pupilOffset(eyeIndex) {
        if (trackCursor && target.x >= 0) {
            // Aim at target from this eye's centre, clamped.
            var cx = eyeIndex * (eyeWidth + eyeSpacing) + eyeWidth / 2
            var cy = eyeHeight / 2
            var dx = target.x - cx
            var dy = target.y - cy
            var len = Math.max(0.001, Math.sqrt(dx*dx + dy*dy))
            var k = Math.min(1, len / (width / 2)) * _maxOffset
            return Qt.point(dx / len * k, dy / len * k)
        }
        return _drift
    }

    // Idle drift: pick a new resting offset every couple of seconds.
    Timer {
        interval: 2200
        running: root.visible
        repeat: true
        onTriggered: {
            var a = Math.random() * Math.PI * 2
            var r = Math.random() * root._maxOffset
            root._drift = Qt.point(Math.cos(a) * r, Math.sin(a) * r * 0.5)
        }
    }

    // Blink: jittered 4–8 s interval, never a metronome (§6.3).
    Timer {
        interval: 4000 + Math.random() * 4000
        running: root.visible
        repeat: true
        onTriggered: {
            interval = 4000 + Math.random() * 4000
            blinkAnim.restart()
        }
    }

    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: root; property: "_blink"; to: 0.08; duration: 70 }
        PauseAnimation { duration: 60 }
        NumberAnimation { target: root; property: "_blink"; to: 1; duration: 90 }
    }
}
