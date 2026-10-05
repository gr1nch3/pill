import QtQuick

import "../../services"
import "../../components"
import "../../utils"
import "../controls"

SettingsPage {
    id: root

    actions: [
        {
            label: "Refresh",
            icon: "󰑓",
            onTrigger: root.refresh
        }
    ]

    function refresh() {
        if (Integrations.has("powerprofilesctl"))
            Power.refresh();
    }

    readonly property bool charging: Battery.status === "Charging" || Battery.status === "Full"
    readonly property color batteryColor: charging ? Theme.accent : (Battery.percent <= 20 ? Theme.eyeMoods.alert.color : Theme.accentAlt)

    // ring value animates to the real reading instead of snapping
    property real shownPercent: Battery.percent
    Behavior on shownPercent {
        NumberAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }

    SettingSection {
        icon: "󰐥"
        label: "BATTERY"
    }

    // hero: ring + live status
    Rectangle {
        width: parent.width
        height: 108
        radius: Theme.shape.radius.card
        color: Theme.background
        border.width: Theme.shape.border.width
        border.color: Theme.border

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: Theme.shape.radius.card - 2
            color: Theme.surface
            clip: true

            Row {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 16
                }
                spacing: 18

                Item {
                    width: 78
                    height: 78
                    anchors.verticalCenter: parent.verticalCenter

                    ArcCanvas {
                        anchors.fill: parent
                        value: Math.max(0, Math.min(1, root.shownPercent / 100))
                        arcColor: root.batteryColor
                        trackColor: Theme.highlight
                        lineWidth: 5
                        Behavior on arcColor {
                            ColorAnimation {
                                duration: Theme.motion.normal
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: -2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(root.shownPercent) + "%"
                            color: Theme.text
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.family
                            font.weight: 800
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.charging ? Icons.batteryCharging : "󰁹"
                            color: root.batteryColor
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.mono
                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.motion.normal
                                }
                            }
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: Battery.status === "Unknown" ? "Battery status unavailable" : Battery.status
                        color: Theme.text
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.family
                        font.weight: 700
                    }

                    Text {
                        text: root.charging ? "Plugged in — profile switches follow the cable" : "On battery — active profile below trades speed for life"
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                    }
                }
            }

            // active profile badge
            Rectangle {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 16
                }
                width: profileBadge.implicitWidth + 18
                height: 24
                radius: Theme.shape.radius.hairline
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                border.width: Theme.shape.border.width
                border.color: Theme.accent

                Text {
                    id: profileBadge
                    anchors.centerIn: parent
                    text: Power.profile === "power-saver" ? "SAVER" : (Power.profile === "performance" ? "PERFORMANCE" : "BALANCED")
                    color: Theme.accent
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.family
                    font.weight: 800
                    font.letterSpacing: 0.6
                }
            }
        }
    }

    SettingSection {
        icon: "󰾅"
        label: "POWER PROFILE"
        description: "CPU governor against battery life. Pick with the pictures."
    }

    Row {
        width: parent.width
        spacing: 8

        Repeater {
            model: [
                {
                    key: "power-saver",
                    icon: Icons.powerSaver,
                    label: "Saver",
                    hint: "Quiet, cool, longest"
                },
                {
                    key: "balanced",
                    icon: Icons.powerBalanced,
                    label: "Balanced",
                    hint: "Everyday default"
                },
                {
                    key: "performance",
                    icon: Icons.powerPerf,
                    label: "Performance",
                    hint: "Fastest, hottest"
                }
            ]

            delegate: Rectangle {
                id: profileTile
                required property var modelData
                readonly property bool on: Power.profile === profileTile.modelData.key

                width: (parent.width - 16) / 3
                height: 92
                radius: Theme.shape.radius.card
                color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : (tileHover.hovered ? Theme.surfaceHover : Theme.surface)
                border.width: on ? Theme.shape.border.emphasis : Theme.shape.border.width
                border.color: on ? Theme.accent : Theme.border
                scale: tileHover.hovered && !on ? 1.02 : 1

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.motion.hover
                    }
                }
                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.motion.hover
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.motion.normal
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: profileTile.modelData.icon
                        color: profileTile.on ? Theme.accent : Theme.text
                        font.pixelSize: 30
                        font.family: Theme.font.mono
                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.motion.hover
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: profileTile.modelData.label
                        color: Theme.text
                        font.pixelSize: Theme.font.size.normal
                        font.family: Theme.font.family
                        font.weight: profileTile.on ? 700 : 500
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: profileTile.modelData.hint
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.caption
                        font.family: Theme.font.family
                    }
                }

                HoverHandler {
                    id: tileHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: Power.setProfile(profileTile.modelData.key)
                }
            }
        }
    }

    SettingSection {
        icon: "󰒲"
        label: "IDLE"
    }

    SettingRow {
        icon: "󰒲"
        title: "Idle / Sleep"
        subtitle: "Pause hypridle / swayidle (screen blank and suspend)"
        keywords: "hypridle swayidle blank screen suspend timeout"
        SettingToggle {
            checked: Power.idleEnabled
            onToggled: Power.toggleIdle()
        }
    }
}
