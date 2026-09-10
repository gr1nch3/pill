// Mouth-as-input (PRD §6.3), shared by the session lock and the SDDM
// greeter. Pure QtQuick — no Quickshell imports. Hidden until the bound
// password field has focus, then pulses on keystroke COUNT so nothing about
// password length leaks.

import QtQuick

Item {
    id: root

    implicitWidth: 220
    implicitHeight: 16

    // True while the password TextInput has focus.
    property bool active: false
    // Increment once per accepted keystroke.
    property int keystrokes: 0

    property real _level: 0   // 1 right after a keystroke, decaying to 0

    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    onKeystrokesChanged: {
        _level = 1
        decayAnim.restart()
    }

    // The mouth: a horizontal bar that swells with each keystroke.
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * (0.45 + 0.55 * root._level)
        height: 3 + 9 * root._level
        radius: height / 2
        color: "#e6ecf7"

        Behavior on width { NumberAnimation { duration: 120 } }
    }

    SequentialAnimation {
        id: decayAnim
        NumberAnimation {
            target: root
            property: "_level"
            to: 0
            duration: 380
            easing.type: Easing.OutQuad
        }
    }
}
