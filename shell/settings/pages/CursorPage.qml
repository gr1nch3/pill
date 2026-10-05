import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    property string cursorTheme: ""
    property string iconTheme: ""
    property int cursorSize: 24

    readonly property bool available: Integrations.has("gsettings")

    function refresh() {
        if (!available) return
        getProc.running = false
        getProc.running = true
    }

    function _unquote(s) {
        return String(s).replace(/^'/, "").replace(/'$/, "")
    }

    function setValue(key, value) {
        setProc.command = ["gsettings", "set", "org.gnome.desktop.interface", key,
            key === "cursor-size" ? String(value) : value]
        setProc.running = true
    }

    SettingSection { icon: "󰆿"; label: "POINTER" }

    SettingRow {
        icon: "󰆿"
        title: "Cursor Theme"
        subtitle: "X11/Wayland cursor name (relogin for some apps)"
        SettingEdit {
            value: root.cursorTheme
            placeholder: "Adwaita"
            onAccepted: function(text) { root.cursorTheme = text; root.setValue("cursor-theme", text) }
        }
    }

    SettingRow {
        icon: "󰆿"
        title: "Cursor Size"
        subtitle: "Pixel size of the pointer"
        SettingStepper {
            text: root.cursorSize.toString() + "px"
            onPlus: { root.cursorSize = Math.min(root.cursorSize + 2, 96); root.setValue("cursor-size", root.cursorSize) }
            onMinus: { root.cursorSize = Math.max(root.cursorSize - 2, 16); root.setValue("cursor-size", root.cursorSize) }
        }
    }

    SettingSection { icon: "󰋩"; label: "ICONS" }

    SettingRow {
        icon: "󰋩"
        title: "Icon Theme"
        subtitle: "Icon set used by GTK applications"
        SettingEdit {
            value: root.iconTheme
            placeholder: "Adwaita"
            onAccepted: function(text) { root.iconTheme = text; root.setValue("icon-theme", text) }
        }
    }

    SettingNote { text: root.available ? "" : "gsettings not found — cursor and icon themes stay untouched." }

    Process {
        id: getProc
        command: ["bash", "-c",
            "echo CURSOR=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null); " +
            "echo ICONS=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null); " +
            "echo SIZE=$(gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null)"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var i = line.indexOf("=")
                if (i < 0) return
                var k = line.slice(0, i), v = line.slice(i + 1).trim()
                if (k === "CURSOR") root.cursorTheme = root._unquote(v)
                else if (k === "ICONS") root.iconTheme = root._unquote(v)
                else if (k === "SIZE") root.cursorSize = parseInt(v) || 24
            }
        }
    }

    Process { id: setProc; command: []; running: false }
}
