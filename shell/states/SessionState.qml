import QtQuick

import "../services"
import "../components"
import "../utils"
import "../eyes"

StatePane {
    id: pane
    stateName: "session"
    keyboardFocus: true
    preferredWidth: 340
    preferredHeight: 80
    focus: false

    anchors.fill: parent

    Column {
        anchors.centerIn: parent
        spacing: 8

        EyeFace {
            anchors.horizontalCenter: parent.horizontalCenter
            eyeWidth: 18
            eyeHeight: 13
            eyeSpacing: 7
            baseMood: "alert"
        }

        Row {
            id: root
            spacing: 5
            visible: pane.visible
            focus: visible

            onVisibleChanged: {
                if (visible) {
                    root.currentIndex = 0;
                    root.forceActiveFocus();
                }
            }

            Keys.onEscapePressed: IslandState.closeToIdle()
            Keys.onPressed: function (event) {
                const count = sessionRepeater.count;
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (event.key === Qt.Key_Left || (event.key === Qt.Key_P && ctrl)) {
                    if (root.currentIndex > 0)
                        root.currentIndex--;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right || (event.key === Qt.Key_N && ctrl)) {
                    if (root.currentIndex < count - 1)
                        root.currentIndex++;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    const item = sessionRepeater.itemAt(root.currentIndex);
                    // variable key: itemAt() types as QQuickItem, whose
                    // delegate context property modelData isn't declarable
                    const mdKey = "modelData";
                    if (item && item[mdKey]) {
                        Session.run(item[mdKey].action);
                        IslandState.closeToIdle();
                    }
                    event.accepted = true;
                }
            }

            property int currentIndex: 0

            Repeater {
                id: sessionRepeater
                model: [
                    {
                        icon: Icons.lock,
                        label: "Lock",
                        action: "lock",
                        danger: false
                    },
                    {
                        icon: Icons.logout,
                        label: "Log Out",
                        action: "logout",
                        danger: false
                    },
                    {
                        icon: Icons.suspend,
                        label: "Suspend",
                        action: "suspend",
                        danger: false
                    },
                    {
                        icon: Icons.shutdown,
                        label: "Shutdown",
                        action: "shutdown",
                        danger: true
                    },
                    {
                        icon: Icons.hibernate,
                        label: "Hibernate",
                        action: "hibernate",
                        danger: false
                    },
                    {
                        icon: Icons.reboot,
                        label: "Reboot",
                        action: "reboot",
                        danger: true
                    }
                ]

                IconButton {
                    required property var modelData
                    required property int index
                    icon: modelData.icon
                    danger: modelData.danger || false
                    active: root.currentIndex === index
                    onEntered: root.currentIndex = index
                    onClicked: {
                        Session.run(modelData.action);
                        IslandState.closeToIdle();
                    }
                }
            }
        }
    }
}
