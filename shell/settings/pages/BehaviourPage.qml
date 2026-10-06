import QtQuick

import "../../services"
import "../controls"

SettingsPage {
    id: root

    SettingSection {
        icon: "󰍹"
        label: "BAR"
    }

    SettingRow {
        icon: "󰥔"
        title: "Auto-hide Delay"
        subtitle: "Time before the bar slides away"
        SettingStepper {
            value: Config.autoHideDelay
            from: 100
            to: 10000
            step: 100
            format: function (v) {
                return (v / 1000).toFixed(1) + "s";
            }
            onValueEdited: function (v) {
                Config.set("autoHideDelay", v);
            }
        }
    }

    SettingRow {
        icon: "󰼰"
        title: "Show Delay"
        subtitle: "Hover time before the bar appears"
        SettingStepper {
            value: Config.showDelay
            from: 0
            to: 5000
            step: 50
            format: function (v) {
                return (v / 1000).toFixed(1) + "s";
            }
            onValueEdited: function (v) {
                Config.set("showDelay", v);
            }
        }
    }

    SettingSection {
        icon: "󰅶"
        label: "ON-SCREEN DISPLAY"
    }

    SettingRow {
        icon: "󰅶"
        title: "OSD Timeout"
        subtitle: "How long volume and brightness overlays stay visible"
        SettingStepper {
            value: Config.osdTimeout
            from: 500
            to: 10000
            step: 100
            format: function (v) {
                return (v / 1000).toFixed(1) + "s";
            }
            onValueEdited: function (v) {
                Config.set("osdTimeout", v);
            }
        }
    }
}
