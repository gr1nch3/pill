import QtQuick

import "../../services"
import "../../components"
import "../controls"

SettingsPage {
    id: root

    function refresh() {
        if (Integrations.has("powerprofilesctl")) Power.refresh()
    }

    SettingSection { icon: "󰐥"; label: "POWER" }

    SettingRow {
        icon: "󰁹"
        title: "Battery"
        subtitle: Battery.status
        Text {
            text: Battery.percent + "%"
            color: Theme.text
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family
            font.weight: 600
        }
    }

    SettingRow {
        icon: "󰾅"
        title: "Power Profile"
        subtitle: "CPU governor vs battery life"
        SettingChips {
            options: [
                { value: "power-saver", label: "Saver" },
                { value: "balanced", label: "Balanced" },
                { value: "performance", label: "Performance" }
            ]
            currentValue: Power.profile
            onValueSelected: function(v) { Power.setProfile(v) }
        }
    }

    SettingRow {
        icon: "󰒲"
        title: "Idle / Sleep"
        subtitle: "Pause hypridle / swayidle (screen blank and suspend)"
        SettingToggle {
            checked: Power.idleEnabled
            onToggled: Power.toggleIdle()
        }
    }
}
