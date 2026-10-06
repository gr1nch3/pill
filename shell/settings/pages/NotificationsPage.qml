import QtQuick
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    property bool soundsEnabled: true

    actions: [
        {
            label: "Clear All",
            icon: "󰅖",
            danger: true,
            visible: NotificationManager.notificationList.length > 0,
            onTrigger: function () {
                NotificationManager.clear();
            }
        },
        {
            label: "Refresh",
            icon: "󰑓",
            onTrigger: root.refresh
        }
    ]

    function refresh() {
        getProc.running = false;
        getProc.running = true;
    }

    SettingSection {
        icon: "󰂚"
        label: "SWITCHES"
        description: "The two you flip daily; the rest are details below."
    }

    Row {
        width: parent.width
        spacing: 8

        SettingTile {
            width: (parent.width - 8) / 2
            toggle: true
            active: NotificationManager.doNotDisturb
            icon: NotificationManager.doNotDisturb ? "󰖛" : "󰂚"
            title: "Do Not Disturb"
            hint: "Silence notification popups"
            onToggled: function (v) {
                NotificationManager.doNotDisturb = v;
            }
        }

        SettingTile {
            width: (parent.width - 8) / 2
            toggle: true
            active: root.soundsEnabled
            icon: "󰕾"
            title: "Event Sounds"
            hint: "GTK sounds for notifications"
            onToggled: function (v) {
                root.soundsEnabled = v;
                setProc.command = ["gsettings", "set", "org.gnome.desktop.sound", "event-sounds", v ? "true" : "false"];
                setProc.running = true;
            }
        }
    }

    SettingSection {
        icon: "󰂢"
        label: "POPUPS"
    }

    SettingRow {
        icon: "󰂢"
        title: "Auto-dismiss Timeout"
        subtitle: "How long a notification popup stays on screen"
        SettingStepper {
            value: Config.notificationTimeout
            from: 1000
            to: 30000
            step: 100
            format: function (v) {
                return (v / 1000).toFixed(1) + "s";
            }
            onValueEdited: function (v) {
                Config.set("notificationTimeout", v);
            }
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
            onValueEdited: function (v) {
                Config.set("maxNotifications", v);
            }
        }
    }

    Process {
        id: getProc
        command: ["gsettings", "get", "org.gnome.desktop.sound", "event-sounds"]
        running: false
        stdout: SplitParser {
            onRead: function (line) {
                root.soundsEnabled = line.trim() === "true";
            }
        }
    }

    Process {
        id: setProc
        command: []
        running: false
    }
}
