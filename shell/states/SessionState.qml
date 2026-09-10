import QtQuick
import Quickshell.Io

import "../services"
import "../components"
import "../utils"
import "../eyes"

Row {
    id: root
    anchors.centerIn: parent
    spacing: 5

    Eye {
        eyeWidth: 16; eyeHeight: 12; eyeSpacing: 6
        anchors.verticalCenter: parent.verticalCenter
        moods: Theme.eyeMoods
        mood: "alert"
    }

    opacity: IslandState.state === "session" ? 1 : 0
    visible: opacity > 0
    focus: visible
    Behavior on opacity { NumberAnimation { duration: 150 } }

    property int currentIndex: 0

    onVisibleChanged: {
        if (visible) {
            root.currentIndex = 0
            root.forceActiveFocus()
        }
    }

    Keys.onEscapePressed: IslandState.closeToIdle()
    Keys.onPressed: function(event) {
        const count = sessionRepeater.count
        const ctrl = event.modifiers & Qt.ControlModifier
        if (event.key === Qt.Key_Left || (event.key === Qt.Key_P && ctrl)) {
            if (root.currentIndex > 0) root.currentIndex--
            event.accepted = true
        } else if (event.key === Qt.Key_Right || (event.key === Qt.Key_N && ctrl)) {
            if (root.currentIndex < count - 1) root.currentIndex++
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const item = sessionRepeater.itemAt(root.currentIndex)
            if (item && item.modelData && item.modelData.proc) {
                item.modelData.proc.running = true
                IslandState.closeToIdle()
            }
            event.accepted = true
        }
    }

    Process { id: lockProc;      command: Config.sessionLock;    running: false }
    Process { id: logoutProc;    command: Config.sessionLogout;    running: false }
    Process { id: suspendProc;   command: Config.sessionSuspend;  running: false }
    Process { id: shutdownProc;  command: Config.sessionShutdown;  running: false }
    Process { id: hibernateProc; command: Config.sessionHibernate; running: false }
    Process { id: rebootProc;    command: Config.sessionReboot;    running: false }

    Repeater {
        id: sessionRepeater
        model: [
            { icon: Icons.lock,      label: "Lock",     proc: lockProc,    danger: false },
            { icon: Icons.logout,    label: "Log Out",  proc: logoutProc,    danger: false },
            { icon: Icons.suspend,   label: "Suspend",  proc: suspendProc,  danger: false  },
            { icon: Icons.shutdown,  label: "Shutdown", proc: shutdownProc,  danger: true  },
            { icon: Icons.hibernate, label: "Hibernate",proc: hibernateProc, danger: false },
            { icon: Icons.reboot,    label: "Reboot",   proc: rebootProc,    danger: true  }
        ]

        IconButton {
            required property var modelData
            required property int index
            icon: modelData.icon
            // label: modelData.label
            danger: modelData.danger || false
            active: root.currentIndex === index
            onEntered: root.currentIndex = index
            onClicked: {
                modelData.proc.running = true
                IslandState.closeToIdle()
            }
        }
    }
}
