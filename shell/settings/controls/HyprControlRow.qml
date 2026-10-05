import QtQuick
import "../../components"

import "../../services"

// Renders one HyprSchema control entry: toggle, stepper or text editor.
SettingRow {
    id: row
    required property var control

    readonly property var current: Hyprland.value(control.key)

    function display(v) {
        if (v === undefined || v === null)
            return "—";
        if (row.control.kind === "bool")
            return v ? "On" : "Off";
        if (row.control.kind === "percent")
            return Math.round(Number(v) * 100) + "%";
        return String(v);
    }

    function bumpValue(delta) {
        var cur = Number(row.current);
        if (isNaN(cur))
            return;
        Hyprland.setOption(row.control.key, Math.max(row.control.min, Math.min(row.control.max, cur + delta)));
    }

    readonly property bool hasOptions: row.control.options !== undefined && row.control.options.length > 0

    icon: control.icon
    title: control.label
    subtitle: row.display(row.current)

    SettingToggle {
        visible: row.control.kind === "bool"
        checked: row.current === true
        onToggled: Hyprland.toggleOption(row.control.key)
    }

    SettingStepper {
        visible: row.control.kind === "int" || row.control.kind === "float" || row.control.kind === "percent"
        text: row.display(row.current)
        onPlus: row.bumpValue(row.control.step)
        onMinus: row.bumpValue(-row.control.step)
    }

    SettingSelect {
        visible: row.control.kind === "str" && row.hasOptions
        width: 190
        options: row.control.options || []
        currentValue: row.current === undefined || row.current === null ? "" : String(row.current)
        onValueSelected: function (v) {
            Hyprland.setOption(row.control.key, v);
        }
    }

    SettingEdit {
        visible: row.control.kind === "str" && !row.hasOptions
        value: row.current === undefined || row.current === null ? "" : String(row.current)
        placeholder: "(unset)"
        onAccepted: function (text) {
            Hyprland.setOption(row.control.key, text);
        }
    }
}
