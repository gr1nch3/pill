import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../../utils/shquote.js" as Sh
import "../controls"

SettingsPage {
    id: root

    property var info: ({})
    property string status: ""

    function refresh() {
        infoProc.running = false
        infoProc.running = true
    }

    readonly property var infoKeys: [
        { k: "OS",         icon: "󰌢", label: "System" },
        { k: "KERNEL",     icon: "󰒓", label: "Kernel" },
        { k: "HOST",       icon: "󰌢", label: "Hostname" },
        { k: "UPTIME",     icon: "󰥔", label: "Uptime" },
        { k: "CPU",        icon: "󰻠", label: "CPU" },
        { k: "RAM",        icon: "󰍛", label: "Memory" },
        { k: "GPU",        icon: "󰢮", label: "GPU" },
        { k: "COMPOSITOR", icon: "󰣖", label: "Compositor" },
        { k: "SHELL",      icon: "󰒓", label: "Bubbles" }
    ]

    readonly property var sessionActions: [
        { key: "sessionLock",      icon: "󰌾", title: "Lock",      danger: false },
        { key: "sessionLogout",    icon: "󰍃", title: "Log Out",   danger: false },
        { key: "sessionSuspend",   icon: "󰤄", title: "Suspend",   danger: false },
        { key: "sessionHibernate", icon: "󰒲", title: "Hibernate", danger: false },
        { key: "sessionReboot",    icon: "󰑐", title: "Reboot",    danger: true },
        { key: "sessionShutdown",  icon: "󰐥", title: "Shut Down", danger: true }
    ]

    function sessionCommand(name) {
        var cmd = Config[name]
        if (!cmd || cmd.length === 0) return
        actionProc.command = cmd
        actionProc.running = true
    }

    function copyDiagnostics() {
        var lines = ["Bubbles diagnostics"]
        for (var i = 0; i < infoKeys.length; i++)
            lines.push(infoKeys[i].label + ": " + (info[infoKeys[i].k] || "?"))
        var text = lines.join("\n")
        statusProc.command = ["sh", "-c", "printf '%s' " + Sh.q(text) + " | wl-copy && echo copied"]
        statusProc.running = true
    }

    SettingSection { icon: "󰋜"; label: "SYSTEM" }

    Repeater {
        model: root.infoKeys

        SettingRow {
            required property var modelData
            icon: modelData.icon
            title: modelData.label
            subtitle: root.info[modelData.k] || "…"
        }
    }

    SettingNote { tone: "success"; text: root.status }

    Row {
        spacing: 8
        SettingAction {
            label: "Refresh"
            onClicked: root.refresh()
        }
        SettingAction {
            label: "Copy Diagnostics"
            accent: true
            onClicked: root.copyDiagnostics()
        }
    }

    SettingSection { icon: "󰐥"; label: "SESSION" }

    Grid {
        width: parent.width
        columns: 3
        spacing: 8

        Repeater {
            model: root.sessionActions

            delegate: SettingTile {
                id: sessionTile
                required property var modelData
                width: (parent.width - 16) / 3
                icon: sessionTile.modelData.icon
                title: sessionTile.modelData.title
                hint: Config[sessionTile.modelData.key] && Config[sessionTile.modelData.key].length > 0
                    ? Config[sessionTile.modelData.key][0] : ""
                danger: sessionTile.modelData.danger
                onClicked: root.sessionCommand(sessionTile.modelData.key)
            }
        }
    }

    Process {
        id: infoProc
        command: ["bash", "-c",
            ". /etc/os-release 2>/dev/null; echo \"OS=${PRETTY_NAME:-Linux}\"; " +
            "echo \"KERNEL=$(uname -sr)\"; " +
            "echo \"HOST=$(hostname)\"; " +
            "echo \"UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //')\"; " +
            "echo \"CPU=$(awk -F: '/^model name/{print $2; exit}' /proc/cpuinfo | xargs)\"; " +
            "echo \"RAM=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}')\"; " +
            "echo \"GPU=$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' | head -1 | cut -d: -f3- | xargs)\"; " +
            "echo \"COMPOSITOR=$(hyprctl version 2>/dev/null | head -1 | sed 's/^ *//')\"; " +
            "echo \"SHELL=$(qs --version 2>/dev/null | head -1)\""]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var i = line.indexOf("=")
                if (i < 0) return
                var next = {}
                for (var k in root.info) next[k] = root.info[k]
                next[line.slice(0, i)] = line.slice(i + 1)
                root.info = next
            }
        }
    }

    Process { id: actionProc; command: []; running: false }
    Process {
        id: statusProc
        command: []
        running: false
        stdout: SplitParser { onRead: function(line) { root.status = line.trim() === "copied" ? "Copied to clipboard" : "" } }
    }
}
