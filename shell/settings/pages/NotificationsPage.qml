import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    property bool soundsEnabled: true

    function refresh() {
        getProc.running = false
        getProc.running = true
    }

    SettingSection { icon: "󰂚"; label: "POPUPS" }

    SettingRow {
        icon: "󰂢"
        title: "Auto-dismiss Timeout"
        subtitle: "How long a notification popup stays on screen"
        SettingStepper {
            value: Config.notificationTimeout
            from: 1000
            to: 30000
            step: 100
            format: function(v) { return (v / 1000).toFixed(1) + "s" }
            onValueEdited: function(v) { Config.set("notificationTimeout", v) }
        }
    }

    SettingRow {
        icon: "󰉁"
        title: "History Limit"
        subtitle: "Maximum notifications kept in the list"
        SettingStepper {
            value: Config.maxNotifications
            from: 1
            to: 200
            step: 1
            onValueEdited: function(v) { Config.set("maxNotifications", v) }
        }
    }

    SettingRow {
        icon: NotificationManager.doNotDisturb ? "󰖛" : "󰂚"
        title: "Do Not Disturb"
        subtitle: "Silence notification popups"
        SettingToggle {
            value: NotificationManager.doNotDisturb
            onValueEdited: function(v) { NotificationManager.doNotDisturb = v }
        }
    }

    SettingSection { icon: "󰕾"; label: "SOUNDS" }

    SettingRow {
        icon: "󰕾"
        title: "Event Sounds"
        subtitle: "Play system sounds for notifications and actions (GTK)"
        SettingToggle {
            checked: root.soundsEnabled
            onToggled: {
                root.soundsEnabled = !root.soundsEnabled
                setProc.command = ["gsettings", "set", "org.gnome.desktop.sound", "event-sounds", root.soundsEnabled ? "true" : "false"]
                setProc.running = true
            }
        }
    }

    Process {
        id: getProc
        command: ["gsettings", "get", "org.gnome.desktop.sound", "event-sounds"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.soundsEnabled = line.trim() === "true" }
        }
    }

    Process { id: setProc; command: []; running: false }
}
