import QtQuick

import "../../services"
import "../../components"
import "../../eyes"
import "../controls"

SettingsPage {
    id: root

    SettingSection { icon: "󰍹"; label: "BAR" }

    SettingRow {
        icon: "󰐃"
        title: "Pinned"
        subtitle: "Keep the bar on screen at all times"
        SettingToggle {
            value: Config.pinned
            onValueEdited: function(v) { Config.set("pinned", v) }
        }
    }

    SettingRow {
        icon: "󰇄"
        title: "Pin Mode"
        subtitle: "Reserving space pushes windows down; overlay floats"
        SettingChips {
            options: [{ value: "overlay", label: "Overlay" }, { value: "bar", label: "Bar" }]
            currentValue: Config.pinMode
            onValueSelected: function(v) { Config.set("pinMode", v) }
        }
    }

    SettingRow {
        icon: "󰍎"
        title: "Position"
        subtitle: "Screen edge the bar docks to"
        SettingChips {
            options: [{ value: "top", label: "Top" }, { value: "bottom", label: "Bottom" }]
            currentValue: Config.position
            onValueSelected: function(v) { Config.set("position", v) }
        }
    }

    SettingSection { icon: "󰈈"; label: "EYES" }

    Rectangle {
        width: parent.width
        height: 96
        radius: Theme.shape.radius.row
        color: Theme.background

        EyeFace {
            anchors.centerIn: parent
            eyeWidth: 52; eyeHeight: 36; eyeSpacing: 18
            visible: true
            mood: Config.eyesEnabled ? "active" : "idle"
            opacity: Config.eyesEnabled ? 1 : 0.25
            Behavior on opacity { NumberAnimation { duration: Theme.motion.panel; easing.type: Easing.OutCubic } }
        }
    }

    SettingRow {
        icon: "󰈈"
        title: "Show Eyes"
        subtitle: "The face in panel headers and the lock screen"
        SettingToggle {
            value: Config.eyesEnabled
            onValueEdited: function(v) { Config.set("eyesEnabled", v) }
        }
    }

    SettingRow {
        icon: "󰈈"
        title: "Style"
        subtitle: "Expression shape; mood colour still follows alerts and errors"
        SettingChips {
            options: [
                { value: "normal", label: "Normal" },
                { value: "angry", label: "Angry" },
                { value: "sad", label: "Sad" },
                { value: "surprised", label: "Surprised" },
                { value: "sleepy", label: "Sleepy" }
            ]
            currentValue: Config.eyeVariant
            onValueSelected: function(v) { Config.set("eyeVariant", v) }
        }
    }

    SettingSection { icon: "󰏘"; label: "MOOD PALETTE" }

    Row {
        width: parent.width
        spacing: 8

        Repeater {
            model: [
                { label: "Idle",   color: Theme.eyeMoods.idle.color,   opacity: Theme.eyeMoods.idle.opacity },
                { label: "Active", color: Theme.eyeMoods.active.color, opacity: Theme.eyeMoods.active.opacity },
                { label: "Alert",  color: Theme.eyeMoods.alert.color,  opacity: Theme.eyeMoods.alert.opacity },
                { label: "Error",  color: Theme.eyeMoods.error.color,  opacity: Theme.eyeMoods.error.opacity }
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
                    width: 18; height: 18; radius: 9
                    color: modelData.color
                    opacity: modelData.opacity
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                    text: modelData.label
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                }
            }
        }
    }

    Text {
        width: parent.width
        text: "Moods follow the active theme; alert and error colour alerts and failed actions."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }
}
