import QtQuick
import Quickshell.Io

import "../services"
import "../components"
import "../utils"
import "../eyes"

StatePane {
    id: root
    stateName: "controlcenter"
    pattern: true
    keyboardFocus: true
    preferredWidth: 540
    preferredHeight: 660

    anchors.fill: parent
    anchors.margins: 16

    // ── Audio device labels ────────────────────────────────────────────────
    readonly property string audioDevice: Audio.defaultSink ? Audio.defaultSink.label : ""
    readonly property string inputDevice: Audio.defaultSource ? Audio.defaultSource.label : ""

    // ── Layout ─────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: 10

        // ── Title bar ────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 32

            // Eyes glance at the toggle rows to their right (PRD §6.4).
            // ponytail: A/B the slant sign before locking personality in.
            EyeFace {
                id: ccEyes
                eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                slant: 4
                // Low battery reads as amber alert (PRD §6.3).
                mood: (Battery.percent <= 20 && Battery.status !== "Charging") ? "alert" : "active"
            }

            Text {
                id: titleText
                text: "Control Center"
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: ccEyes.visible ? ccEyes.right : parent.left
                anchors.leftMargin: ccEyes.visible ? 10 : 0
            }

            Rectangle {
                id: settingsBtn
                width: 32; height: 32; radius: Theme.shape.radius.row
                color: settingsHover.containsMouse ? Theme.surfaceHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: powerBtn.left //; anchors.rightMargin: 3
                Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.xlarge
                    font.family: Theme.font.mono
                }

                MouseArea {
                    id: settingsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: IslandState.open("settings")
                }
            }

            Rectangle {
                id: powerBtn
                width: 32; height: 32; radius: Theme.shape.radius.row
                color: powerHover.containsMouse ? Theme.danger : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    color: powerHover.containsMouse ? Theme.background : Theme.subtext
                    font.pixelSize: Theme.font.size.xlarge
                    font.family: Theme.font.mono
                }

                MouseArea {
                    id: powerHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: IslandState.open("session")
                }
            }

        }

        // ── Large toggle tiles ───────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 5

            ToggleTile {
                width: (parent.width - 20) / 3
                icon: Network.wifiEnabled ? "󰤨" : "󰤭"
                title: "Wi-Fi"
                subtitle: Network.wifiEnabled ? (Network.wifiName || "On") : "Off"
                btnActive: Network.wifiEnabled
                onIconClicked: Network.toggleWifi()
                onClicked: {
                    IslandState.deviceSelectType = "wifi"
                    IslandState.open("connectivity")
                }
            }

            ToggleTile {
                width: (2 * parent.width - 10) / 3
                icon: Audio.muted ? "󰝟" : "󰕾"
                title: "Audio"
                subtitle: root.audioDevice || "Output"
                btnActive: !Audio.muted
                onIconClicked: Audio.toggleMute()
                onClicked: {
                    IslandState.deviceSelectType = "audio"
                    IslandState.open("audiodevice")
                }
            }
        }

        // ── Power profile + Bluetooth  ────────────────────────────────────
        Row {
            width: parent.width
            spacing: 5

            Rectangle {
              width: (parent.width - 10) / 2
                height: 64
                radius: Theme.shape.radius.row
                color: Theme.background

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: [
                            { key: "power-saver", icon: Icons.powerSaver },
                            { key: "balanced", icon: Icons.powerBalanced },
                            { key: "performance", icon: Icons.powerPerf }
                        ]
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            property bool isActive: Power.profile === modelData.key

                            width: (parent.parent.width - 25) / 3; height: 50; radius: Theme.shape.radius.control
                            color: isActive ? Theme.accent : (chipMouse.containsMouse ? Theme.surfaceHover : "transparent")
                            border.width: isActive ? 0 : Theme.shape.border.width
                            border.color: Theme.border
                            Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: isActive ? Theme.background : Theme.text
                                font.pixelSize: Theme.font.size.xlarge
                                font.family: Theme.font.mono
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
onClicked: Power.setProfile(modelData.key)
                            }
                        }
                    }
                }
            }

            ToggleTile {
                id: btTile
                width: (parent.width - 20) / 2
                height: 64
                icon: Bluetooth.powered ? "󰂯" : (Bluetooth.blocked ? "󰂰" : "󰂲")
                title: "BT"
                subtitle: Bluetooth.blocked ? "Blocked" : (Bluetooth.powered ? "On" : "Off")
                btnActive: Bluetooth.powered
                onIconClicked: Bluetooth.togglePower()
                onClicked: {
                    IslandState.deviceSelectType = "bluetooth"
                    IslandState.open("connectivity")
                }
            }

        }

        // ── Focus + Sleep + Mic tiles ────────────────────────────────
        Row {
            width: parent.width
            spacing: 10

            ToggleTile {
                width: (parent.width - 50) / 6
                icon: NotificationManager.doNotDisturb ? Icons.dndOn : Icons.dndOff
                title: "Focus"
                subtitle: NotificationManager.doNotDisturb ? "On" : "Off"
                tileActive: NotificationManager.doNotDisturb
                iconButton: false
                onIconClicked: NotificationManager.doNotDisturb = !NotificationManager.doNotDisturb
                onClicked: NotificationManager.doNotDisturb = !NotificationManager.doNotDisturb
            }

            ToggleTile {
                width: (parent.width - 50) / 6
                icon: Icons.suspend
                title: "Sleep"
                subtitle: Power.idleEnabled ? "On" : "Off"
                tileActive: Power.idleEnabled
                iconButton: false
                onIconClicked: Power.toggleIdle()
                onClicked: Power.toggleIdle()
            }

            ToggleTile {
                width: (2 * parent.width - 10) / 3
                icon: Audio.micMuted ? Icons.micOff : Icons.micOn
                title: "Mic"
                subtitle: Audio.micMuted ? "Muted" : (root.inputDevice || "Input")
                btnActive: !Audio.micMuted
                onIconClicked: Audio.toggleMic()
                onClicked: {
                    IslandState.deviceSelectType = "mic"
                    IslandState.open("audiodevice")
                }
            }
        }

        // ── Volume slider ────────────────────────────────────────────────
        Slider {
            width: parent.width
            value: Audio.percent
            fillColor: Theme.accent
            icon: Audio.percent === 0 || Audio.muted ? "󰝟" : "󰕾"
            onValueChangedByUser: function(pct) { Audio.setPercent(pct) }
            onIconClicked: Audio.toggleMute()
        }

        // ── Brightness slider ────────────────────────────────────────────
        Slider {
            width: parent.width
            value: Brightness.percent
            fillColor: Theme.accentAlt
            icon: "󰃠"
            onValueChangedByUser: function(pct) { Brightness.setPercent(pct) }
        }

        // ── System Monitor ──────────────────────────────────────────────
        Item {
            width: parent.width
            height: 68

            Row {
                anchors.fill: parent
                spacing: 6

                StatCard {
                    cardIcon: "󰻠"
                    iconColor: Theme.accentAlt
                    cardValue: SystemStats.cpuPercent
                    accentColor: Theme.accentAlt
                }

                StatCard {
                    cardIcon: "󰍛"
                    iconColor: Theme.accent
                    cardValue: SystemStats.ramPercent
                    accentColor: Theme.accent
                }

                StatCard {
                    cardIcon: "󰋊"
                    iconColor: Theme.subtext
                    cardValue: SystemStats.diskPercent
                    accentColor: Theme.subtext
                }
            }
        }

        // ── Notifications section ────────────────────────────────────────
        Item {
            id: notifSection
            width: parent.width
            height: parent.height - notifSection.y

            Row {
                id: notifHeader
                anchors.top: parent.top
                width: parent.width
                Text {
                    text: "Notifications"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.family
                    font.bold: true
                    width: parent.width - 50
                }
                Text {
                    text: "Clear all"
                    color: clearAllCCHover.containsMouse ? Theme.danger : Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    visible: NotificationManager.notificationList.length > 0
                    Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                    MouseArea { id: clearAllCCHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: NotificationManager.clear() }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: NotificationManager.notificationList.length === 0
                text: "No notifications"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
                width: parent.width; horizontalAlignment: Text.AlignHCenter
            }

            ListView {
                anchors.top: notifHeader.bottom
                anchors.topMargin: 8
                anchors.bottom: parent.bottom
                width: parent.width
                visible: NotificationManager.notificationList.length > 0
                clip: true
                spacing: 6
                model: NotificationManager.notificationList

                delegate: Rectangle {
                    width: ListView.view.width
                    height: Math.max(48, notifRow.implicitHeight + 16)
                    radius: Theme.shape.radius.card
                    color: modelData.urgency === 2 ? Theme.dangerBg : Theme.background
                    required property var modelData
                    required property int index

                    NotificationRow {
                        id: notifRow
                        anchors {
                            left: parent.left; right: parent.right
                            leftMargin: 10; rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        notification: modelData
                        expanded: true
                        bodyLines: 2
                        showDismiss: true
                        iconSize: 28
                        iconRadius: 6
                        onDismissed: NotificationManager.dismiss(modelData.id)
                    }
                }
            }
        }
    }
}
