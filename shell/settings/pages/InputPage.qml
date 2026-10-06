import QtQuick

import "../../services"
import "../controls"
import "../../utils/HyprSchema.js" as HyprSchema

SettingsPage {
    id: root

    actions: [
        {
            label: "Re-read",
            icon: "󰑓",
            onTrigger: root.refresh
        }
    ]

    readonly property var groups: HyprSchema.groups.filter(function (g) {
        return g.page === "input";
    })
    readonly property var optionKeys: {
        var keys = [];
        for (var i = 0; i < groups.length; i++)
            for (var j = 0; j < groups[i].controls.length; j++)
                keys.push(groups[i].controls[j].key);
        return keys;
    }

    function refresh() {
        if (active)
            Hyprland.readOptions(root.optionKeys);
    }

    SettingNote {
        visible: !Hyprland.available
        text: "Hyprland not detected — input settings need hyprctl. Values are applied at runtime and re-applied when the shell starts."
    }

    Repeater {
        model: root.groups

        delegate: Column {
            id: inputGroup
            required property var modelData
            width: root.width
            spacing: 4
            visible: Hyprland.available

            SettingSection {
                label: inputGroup.modelData.name.toUpperCase()
            }

            Repeater {
                model: inputGroup.modelData.controls
                delegate: HyprControlRow {
                    required property var modelData
                    control: modelData
                }
            }
        }
    }

    SettingNote {
        text: "Layout accepts comma-separated names (e.g. \"us,de\"); accel profile is adaptive or flat. hyprctl reload resets runtime values — Pill re-applies them on next start."
    }
}
