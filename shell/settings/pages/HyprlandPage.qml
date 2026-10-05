import QtQuick
import "../../components"

import "../../services"
import "../controls"
import "../../utils/HyprSchema.js" as HyprSchema

SettingsPage {
    id: root

    readonly property var groups: HyprSchema.groups.filter(function(g) { return g.page === "hyprland" })
    readonly property var optionKeys: {
        var keys = []
        for (var i = 0; i < groups.length; i++)
            for (var j = 0; j < groups[i].controls.length; j++)
                keys.push(groups[i].controls[j].key)
        return keys
    }

    function refresh() {
        if (active) Hyprland.readOptions(root.optionKeys)
    }

    SettingSection { icon: "󰣖"; label: "HYPRLAND" }

    SettingNote {
        visible: !Hyprland.available
        text: "Hyprland not detected — hyprctl unavailable. Values are applied at runtime and re-applied when the shell starts; a hyprctl reload resets them."
    }

    Repeater {
        model: root.groups

        delegate: Column {
            id: hyprGroup
            required property var modelData
            width: root.width
            spacing: 4
            visible: Hyprland.available

            SettingSection { label: hyprGroup.modelData.name.toUpperCase() }

            Repeater {
                model: hyprGroup.modelData.controls
                delegate: HyprControlRow {
                    required property var modelData
                    control: modelData
                }
            }
        }
    }
}
