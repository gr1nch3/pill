import QtQuick

import "../../services"
import "../../components"
import "../controls"

SettingsPage {
    id: root

    SettingSection { icon: "󰎆"; label: "TYPOGRAPHY" }

    SettingRow {
        icon: "󰎆"
        title: "Font Family"
        subtitle: "UI text font — blank uses the system font"
        SettingEdit {
            value: Config.fontFamily
            placeholder: "(system)"
            onAccepted: function(text) { Config.set("fontFamily", text) }
        }
    }

    SettingRow {
        icon: "󰋜"
        title: "Icon Font"
        subtitle: "Font used for glyph icons"
        SettingEdit {
            value: Config.iconFontFamily
            placeholder: "(none)"
            onAccepted: function(text) { Config.set("iconFontFamily", text) }
        }
    }

    SettingRow {
        icon: "󰁃"
        title: "Font Scale"
        subtitle: "Scales every label in the shell"
        SettingStepper {
            value: Config.fontScale
            from: 0.5
            to: 2.0
            step: 0.1
            format: function(v) { return v.toFixed(1) + "x" }
            onValueEdited: function(v) { Config.set("fontScale", v) }
        }
    }

    SettingSection { icon: "󰎆"; label: "PREVIEW" }

    Rectangle {
        width: parent.width
        height: 84
        radius: Theme.shape.radius.row
        color: Theme.background

        Text {
            anchors.centerIn: parent
            text: "The quick brown fox jumps over the lazy dog"
            color: Theme.text
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family
        }
    }
}
