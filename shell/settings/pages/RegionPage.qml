import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    property var status: ({})

    function refresh() {
        if (!Integrations.has("localectl")) return
        statusProc.running = false
        statusProc.running = true
    }

    SettingSection { icon: "󰗊"; label: "REGION & LANGUAGE" }

    Repeater {
        model: [
            { k: "LANG",    label: "System Language", icon: "󰗊" },
            { k: "LC_TIME", label: "Time Formatting", icon: "󰅐" },
            { k: "X11LAYOUT", label: "Keyboard Layout", icon: "󰌌" },
            { k: "X11MODEL", label: "Keyboard Model", icon: "󰌌" },
            { k: "VCKEYMAP", label: "Console Keymap", icon: "󰌌" }
        ]

        SettingRow {
            required property var modelData
            icon: modelData.icon
            title: modelData.label
            subtitle: root.status[modelData.k] || "…"
        }
    }

    Text {
        visible: Object.keys(root.status).length === 0
        width: parent.width
        text: "localectl not found — locale information unavailable."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
    }

    Text {
        width: parent.width
        text: "Changing the system locale or keymap is a system-wide write; Bubbles shows it read-only here. Use localectl (with polkit) or the compositor's input settings for runtime changes."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }

    Process {
        id: statusProc
        command: ["localectl", "status"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var i = line.indexOf(":")
                if (i < 0) return
                var key = line.slice(0, i).trim()
                var val = line.slice(i + 1).trim()
                var k = ""
                if (key === "System Locale") k = "LANG"
                else if (key === "Time zone") k = "LC_TIME"
                else if (key === "X11 Layout") k = "X11LAYOUT"
                else if (key === "X11 Model") k = "X11MODEL"
                else if (key === "VC Keymap") k = "VCKEYMAP"
                if (k === "") return
                var next = {}
                for (var j in root.status) next[j] = root.status[j]
                next[k] = val.replace(/^LANG=/, "")
                if (k === "LANG") {
                    var m = val.match(/LANG=(\S+)/)
                    next[k] = m ? m[1] : val
                    var tm = val.match(/LC_TIME=(\S+)/)
                    if (tm) next["LC_TIME"] = tm[1]
                }
                root.status = next
            }
        }
    }
}
