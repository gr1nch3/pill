import QtQuick
import "../../components"

import "../../services"
import "../controls"

SettingsPage {
    id: root

    property string modeTarget: ""

    readonly property var scaleValues: [1, 1.25, 1.5, 1.75, 2]

    function currentScaleIndex(m) {
        var best = 0
        var dist = 99
        for (var i = 0; i < scaleValues.length; i++) {
            var d = Math.abs(scaleValues[i] - Number(m.scale))
            if (d < dist) { dist = d; best = i }
        }
        return best
    }

    function modeLabel(mode) {
        return String(mode).replace("Hz", "")
    }

    function modeString(m) {
        return m.width + "x" + m.height + "@" + Number(m.refreshRate).toFixed(2)
    }

    function refresh() { Hyprland.refreshMonitors() }

    SettingSection { icon: "󰍹"; label: "DISPLAYS" }

    Text {
        visible: !Hyprland.monitorsAvailable
        width: parent.width
        text: "No monitors detected via hyprctl.\nThe monitor rule is applied at runtime and re-applied when the shell starts."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: Hyprland.monitors

        delegate: Column {
            id: monitorCol
            required property var modelData
            width: root.width
            spacing: 4

            SettingSection { label: modelData.name.toUpperCase() + (modelData.description ? " — " + modelData.description : "") }

            SettingRow {
                icon: "󰍹"
                title: "Resolution"
                subtitle: root.modeString(monitorCol.modelData)
                    + (monitorCol.modelData.availableModes && monitorCol.modelData.availableModes.length > 0
                        ? " • " + monitorCol.modelData.availableModes.length
                            + (monitorCol.modelData.availableModes.length === 1 ? " mode" : " modes")
                        : "")
                SettingAction {
                    label: root.modeTarget === monitorCol.modelData.name ? "Close" : "Change"
                    onClicked: root.modeTarget = root.modeTarget === monitorCol.modelData.name ? "" : monitorCol.modelData.name
                }
            }

            Repeater {
                model: root.modeTarget === monitorCol.modelData.name && monitorCol.modelData.availableModes
                    ? monitorCol.modelData.availableModes : []

                delegate: SettingRow {
                    required property var modelData
                    icon: "󰍹"
                    title: root.modeLabel(modelData)
                    subtitle: root.modeLabel(modelData) === root.modeString(monitorCol.modelData) ? "Current" : "Apply"
                    SettingAction {
                        label: "Use"
                        accent: true
                        onClicked: {
                            Hyprland.setMonitorMode(monitorCol.modelData.name, root.modeLabel(modelData))
                            root.modeTarget = ""
                        }
                    }
                }
            }

            SettingRow {
                icon: "󰍹"
                title: "Scale"
                subtitle: "UI scale for this output"
                SettingChips {
                    options: ["100%", "125%", "150%", "175%", "200%"]
                    currentIndex: root.currentScaleIndex(monitorCol.modelData)
                    onSelected: function(index) { Hyprland.setMonitorScale(monitorCol.modelData.name, root.scaleValues[index]) }
                }
            }

            SettingRow {
                icon: "󰓡"
                title: "Rotation"
                subtitle: "Display orientation"
                SettingChips {
                    options: ["Normal", "90°", "180°", "270°"]
                    currentIndex: Math.min(3, Number(monitorCol.modelData.transform) || 0)
                    onSelected: function(index) { Hyprland.setMonitorTransform(monitorCol.modelData.name, index) }
                }
            }
        }
    }
}
