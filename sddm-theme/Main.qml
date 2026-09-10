// Bubbles SDDM greeter (PRD §5.2/§6.6).
// Imports the SAME Eye.qml + Mouth.qml the session lock uses — one identity,
// not two implementations drifting apart. Eye.qml/Mouth.qml are copied into
// this directory at package time (see PKGBUILD) so the theme is
// self-contained, as SDDM requires.
//
// Deliberate divergence from SessionLock (§6.6): this surface carries the
// AccountSwitcher; the session lock never does.

import QtQuick
import QtQuick.Controls.Basic
import Sddm 1.0

Rectangle {
    id: root

    // ── Palette: snapshot written by the shell, embedded fallback if missing.
    // A cosmetic theme failure must never block login (ryoku lesson).
    property var pal: ({
        background: "#0b0b10", surface: "#15151a", accent: "#4ecdc4",
        text: "#f0f0f5", subtext: "#8a8a99", danger: "#ff6b6b",
        border: "#28a8a899"
    })

    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///etc/xdg/bubbles/greeter-palette.json", false)
        xhr.send()
        if (xhr.status === 200) {
            try { root.pal = JSON.parse(xhr.responseText) }
            catch (e) console.warn("bubbles greeter: bad palette JSON, using fallback")
        } else {
            console.warn("bubbles greeter: no palette snapshot, using fallback")
        }
    }

    color: pal.background

    UserModel { id: userModel }
    SessionModel { id: sessionModel }

    property string currentUser: userModel.lastUser
    property string password: ""

    // ── Face ────────────────────────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 18

        Eye {
            anchors.horizontalCenter: parent.horizontalCenter
            eyeWidth: 64; eyeHeight: 44; eyeSpacing: 28
            moods: ({
                idle:   { color: root.pal.subtext, opacity: 0.55 },
                active: { color: root.pal.accent, opacity: 1.0 },
                alert:  { color: "#f0a500", opacity: 1.0 },
                error:  { color: root.pal.danger, opacity: 1.0 }
            })
            mood: root.authState === "error" ? "error" : (passwordField.activeFocus ? "active" : "idle")
        }

        Mouth {
            id: mouth
            anchors.horizontalCenter: parent.horizontalCenter
            active: passwordField.activeFocus
            keystrokes: root._keystrokeCount
        }

        AccountSwitcher {
            id: switcher
            anchors.horizontalCenter: parent.horizontalCenter
            userModel: userModel
            pal: root.pal
            onUserPicked: name => root.currentUser = name
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentUser
            visible: switcher.accountCount > 1
            color: root.pal.subtext
            font.pixelSize: 14
        }
    }

    property string authState: "idle"
    property int _keystrokeCount: 0

    // ── Password input: real field, invisible — the face is the UI (§6.3) ──
    TextInput {
        id: passwordField
        anchors.centerIn: parent
        width: 1; height: 1
        opacity: 0
        echoMode: TextInput.Password
        focus: true
        onTextChanged: { root.password = text; root._keystrokeCount++ }
        onAccepted: root.tryLogin()
        // Keyboard-first account switching (§6.6): arrows or Tab cycle.
        Keys.onLeftPressed: switcher.cycle(-1)
        Keys.onRightPressed: switcher.cycle(1)
        Keys.onTabPressed: switcher.cycle(event.modifiers & Qt.ShiftModifier ? -1 : 1)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: passwordField.forceActiveFocus()
    }

    function tryLogin() {
        if (!password) return
        root.authState = "idle"
        sddm.login(root.currentUser, password, sessionModel.lastIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.authState = "error"
            passwordField.text = ""
            passwordField.forceActiveFocus()
            failTimer.restart()
        }
    }

    Timer {
        id: failTimer
        interval: 2000
        onTriggered: root.authState = "idle"
    }
}
