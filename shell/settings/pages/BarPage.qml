import QtQuick

import "../../services"
import "../../components"
import "../../eyes"
import "../controls"

SettingsPage {
    id: root

    SettingRow {
        icon: "󰐃"
        title: "Pinned"
        subtitle: "Keep the bar on screen at all times"
        SettingToggle {
            value: Config.pinned
            onValueEdited: function (v) {
                Config.set("pinned", v);
            }
        }
    }

    SettingRow {
        icon: "󰇄"
        title: "Pin Mode"
        subtitle: "Reserving space pushes windows down; overlay floats"
        SettingChips {
            options: [
                {
                    value: "overlay",
                    label: "Overlay"
                },
                {
                    value: "bar",
                    label: "Bar"
                }
            ]
            currentValue: Config.pinMode
            onValueSelected: function (v) {
                Config.set("pinMode", v);
            }
        }
    }

    SettingRow {
        icon: "󰍎"
        title: "Position"
        subtitle: "Screen edge the bar docks to"
        SettingChips {
            options: [
                {
                    value: "top",
                    label: "Top"
                },
                {
                    value: "bottom",
                    label: "Bottom"
                }
            ]
            currentValue: Config.position
            onValueSelected: function (v) {
                Config.set("position", v);
            }
        }
    }

    SettingSection {
        icon: "󰈈"
        label: "EYES"
    }

    // Live shell mock: where the bar docks, whether windows make room, and
    // whether the face rides in it.
    Item {
        id: barMock
        width: parent.width
        height: 172

        readonly property bool reserves: Config.pinned && Config.pinMode === "bar"
        readonly property real windowShift: barMock.reserves ? (Config.position === "top" ? 13 : -13) : 0

        Rectangle {
            anchors.fill: parent
            radius: Theme.shape.radius.card
            color: Theme.background
            border.width: Theme.shape.border.width
            border.color: Theme.border
            clip: true

            PatternBackground {
                anchors.fill: parent
                variant: "dots"
                spacing: 26
                strength: 0.06
                color: Theme.accent
                shape: "rounded"
                radius: parent.radius
            }

            // desktop content: moves when the pinned bar reserves space
            Rectangle {
                id: mockWindow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                property real shift: barMock.windowShift
                anchors.verticalCenterOffset: shift
                Behavior on shift {
                    NumberAnimation {
                        duration: Theme.motion.panel
                        easing.type: Easing.OutCubic
                    }
                }

                width: parent.width * 0.62
                height: 78
                radius: Theme.shape.radius.row
                color: Theme.surface
                border.width: Theme.shape.border.width
                border.color: Theme.border

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 7

                    Repeater {
                        model: [0.5, 0.8, 0.35]
                        Rectangle {
                            required property real modelData
                            width: parent.width * modelData
                            height: 6
                            radius: 3
                            color: Theme.highlight
                        }
                    }
                }
            }

            // the bar strip
            Rectangle {
                id: mockBar
                width: parent.width * 0.8
                height: 24
                radius: 12
                color: Theme.surface
                border.width: Theme.shape.border.width
                border.color: Theme.border
                opacity: Config.pinned ? 1 : 0.35
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.motion.panel
                        easing.type: Easing.OutCubic
                    }
                }
                x: (parent.width - width) / 2
                y: Config.position === "top" ? 10 : parent.height - height - 10
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.motion.panel
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    EyeFace {
                        eyeWidth: 11
                        eyeHeight: 8
                        eyeSpacing: 5
                        baseMood: "active"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "12:34"
                        color: Theme.text
                        font.pixelSize: Theme.font.size.caption
                        font.family: Theme.font.mono
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: [0.9, 0.6, 0.35]
                            Rectangle {
                                required property real modelData
                                width: 4
                                height: 10
                                radius: 2
                                color: Theme.subtext
                                opacity: modelData
                            }
                        }
                    }
                }
            }

            // how the pin behaves, said once
            Rectangle {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    margins: 10
                }
                width: modeText.implicitWidth + 14
                height: 20
                radius: Theme.shape.radius.hairline
                color: Theme.background
                border.width: Theme.shape.border.width
                border.color: barMock.reserves ? Theme.accent : Theme.border
                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.motion.hover
                    }
                }

                Text {
                    id: modeText
                    anchors.centerIn: parent
                    text: !Config.pinned ? "AUTO-HIDE" : (barMock.reserves ? "RESERVED" : "OVERLAY")
                    color: barMock.reserves ? Theme.accent : Theme.subtext
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.mono
                    font.weight: 700
                }
            }
        }
    }

    SettingRow {
        icon: "󰈈"
        title: "Show Eyes"
        subtitle: "The face in panel headers and the lock screen"
        keywords: "face robot anime mascot"
        SettingToggle {
            value: Config.eyesEnabled
            onValueEdited: function (v) {
                Config.set("eyesEnabled", v);
            }
        }
    }

    SettingRow {
        icon: "󰈈"
        title: "Style"
        subtitle: "Expression shape; mood colour still follows alerts and errors"
        SettingChips {
            options: [
                {
                    value: "normal",
                    label: "Normal"
                },
                {
                    value: "angry",
                    label: "Angry"
                },
                {
                    value: "sad",
                    label: "Sad"
                },
                {
                    value: "surprised",
                    label: "Surprised"
                },
                {
                    value: "sleepy",
                    label: "Sleepy"
                }
            ]
            currentValue: Config.eyeVariant
            onValueSelected: function (v) {
                Config.set("eyeVariant", v);
            }
        }
    }

    SettingSection {
        icon: "󰏘"
        label: "MOOD PALETTE"
        description: "Moods follow the active theme; alert and error colour alerts and failed actions."
    }

    Row {
        width: parent.width
        spacing: 8

        Repeater {
            model: [
                {
                    label: "Idle",
                    color: Theme.eyeMoods.idle.color,
                    opacity: Theme.eyeMoods.idle.opacity
                },
                {
                    label: "Active",
                    color: Theme.eyeMoods.active.color,
                    opacity: Theme.eyeMoods.active.opacity
                },
                {
                    label: "Alert",
                    color: Theme.eyeMoods.alert.color,
                    opacity: Theme.eyeMoods.alert.opacity
                },
                {
                    label: "Error",
                    color: Theme.eyeMoods.error.color,
                    opacity: Theme.eyeMoods.error.opacity
                }
            ]

            delegate: Rectangle {
                required property var modelData
                width: (parent.width - 24) / 4
                height: 64
                radius: Theme.shape.radius.row
                color: Theme.background

                Rectangle {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -8
                    width: 18
                    height: 18
                    radius: 9
                    color: modelData.color
                    opacity: modelData.opacity
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 8
                    }
                    text: modelData.label
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                }
            }
        }
    }
}
