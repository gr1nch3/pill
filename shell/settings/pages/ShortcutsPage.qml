import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [{ label: "Refresh", icon: "󰑓", onTrigger: root.refresh }]

    property var binds: []
    property string filterText: ""
    property string _appliedFilter: ""

    // one rebuild per typing pause instead of one per keystroke: each rebuild
    // re-creates every visible bind row (hundreds of them)
    onFilterTextChanged: filterDebounce.restart()

    Timer {
        id: filterDebounce
        interval: 140
        onTriggered: root._appliedFilter = root.filterText
    }

    readonly property var filtered: {
        var q = _appliedFilter.trim().toLowerCase()
        var out = []
        for (var i = 0; i < binds.length; i++) {
            var b = binds[i]
            if (q === "" || b.keys.toLowerCase().indexOf(q) !== -1
                || b.action.toLowerCase().indexOf(q) !== -1) out.push(b)
        }
        return out
    }

    function mods(mask) {
        var m = Number(mask) || 0
        var out = []
        if (m & 64) out.push("SUPER")
        if (m & 4) out.push("CTRL")
        if (m & 1) out.push("SHIFT")
        if (m & 8) out.push("ALT")
        if (m & 2) out.push("CAPS")
        return out
    }

    function keyLabel(b) {
        var key = String(b.key || "")
        if (key.indexOf("code:") === 0) key = "code " + key.slice(5)
        var m = mods(b.modmask)
        return (m.length > 0 ? m.join(" + ") + " + " : "") + key
    }

    function refresh() {
        if (!Integrations.has("hyprctl")) return
        root.binds = []
        bindsProc.running = false
        bindsProc.running = true
    }

    SettingRow {
        icon: "󰍉"
        title: "Filter"
        subtitle: "Type to search keys or actions"
        SettingEdit {
            width: 260
            live: true
            value: root.filterText
            placeholder: "Keys or actions"
            onTextEdited: function(text) { root.filterText = text }
        }
    }

    SettingNote { text: root.filtered.length + " of " + root.binds.length + " binds" }

    Repeater {
        model: root.filtered

        SettingRow {
            required property var modelData
            icon: modelData.mouse ? "󰍽" : "󰌌"
            title: modelData.keys
            subtitle: modelData.action
        }
    }

    SettingNote {
        visible: !Integrations.has("hyprctl")
        text: "Hyprland not detected — keybinds come from hyprctl."
    }

    SettingNote {
        text: "Read-only: bindings live in your compositor config (and its lua modules). Actions shown as `lua handler #N` are defined in a lua config — hyprctl only exposes the dispatcher id. Runtime `hyprctl keyword bind` changes are reset by reload."
    }

    property string _buf: ""
    Process {
        id: bindsProc
        command: ["bash", "-c", "hyprctl -j binds 2>/dev/null || echo '[]'"]
        running: false
        stdout: SplitParser { onRead: function(line) { root._buf += line } }
        onExited: {
            try {
                var arr = JSON.parse(root._buf)
                var out = []
                for (var i = 0; i < arr.length; i++) {
                    var b = arr[i]
                    var action = String(b.dispatcher || "")
                    if (b.arg) action += (action === "__lua" ? " handler #" + b.arg : " " + b.arg)
                    else if (action === "__lua") action = "lua handler"
                    out.push({
                        mouse: !!b.mouse,
                        keys: root.keyLabel(b),
                        action: action
                    })
                }
                root.binds = out
            } catch (e) {
                root.binds = []
            }
            root._buf = ""
        }
    }
}
