import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [{ label: "Refresh", icon: "󰑓", onTrigger: root.refresh }]

    property var defaults: ({})
    property string targetMime: ""
    property var handlers: []
    property string status: ""

    readonly property var categories: [
        { mime: "x-scheme-handler/http", label: "Web Browser",  icon: "󰖟" },
        { mime: "x-scheme-handler/mailto", label: "Email",      icon: "󰇮" },
        { mime: "inode/directory",      label: "File Manager",  icon: "󰉋" },
        { mime: "text/plain",           label: "Text Editor",   icon: "󰈙" },
        { mime: "image/png",            label: "Image Viewer",  icon: "󰋩" },
        { mime: "video/mp4",            label: "Video Player",  icon: "󰕧" },
        { mime: "audio/mpeg",           label: "Audio Player",  icon: "󰎇" }
    ]

    function refresh() {
        if (!Integrations.has("xdg-mime")) return
        defaultsProc.running = false
        defaultsProc.running = true
    }

    function openHandlers(mime) {
        targetMime = targetMime === mime ? "" : mime
        handlers = []
        if (targetMime === "") return
        handlersProc.command = ["bash", "-c",
            "for f in /usr/share/applications/*.desktop \"$HOME\"/.local/share/applications/*.desktop; do\n" +
            "  [ -f \"$f\" ] || continue\n" +
            "  grep -q \"^MimeType=.*" + mime + "\" \"$f\" 2>/dev/null || continue\n" +
            "  name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-)\n" +
            "  printf '%s\\t%s\\n' \"$name\" \"$f\"\n" +
            "done | sort -u | head -16"]
        handlersProc.running = true
    }

    function setDefault(mime, file) {
        setProc.command = ["xdg-mime", "default", file.split("/").pop(), mime]
        setProc.running = true
        status = "Default set"
    }

    Repeater {
        model: root.categories

        SettingRow {
            id: appRow
            required property var modelData
            icon: appRow.modelData.icon
            title: appRow.modelData.label
            subtitle: root.defaults[appRow.modelData.mime]
                ? root.defaults[appRow.modelData.mime].replace(".desktop", "")
                : "Not set"
            SettingAction {
                label: root.targetMime === appRow.modelData.mime ? "Close" : "Change"
                onClicked: root.openHandlers(appRow.modelData.mime)
            }
        }
    }

    SettingNote {
        visible: root.targetMime !== ""
        text: "Choose a handler for " + root.targetMime + ":"
    }

    Repeater {
        model: root.targetMime !== "" ? root.handlers : []

        SettingRow {
            required property var modelData
            icon: "󰈙"
            title: modelData.name
            subtitle: modelData.file.split("/").pop()
            SettingAction {
                label: "Set"
                accent: true
                onClicked: {
                    root.setDefault(root.targetMime, modelData.file)
                    root.targetMime = ""
                }
            }
        }
    }

    SettingNote {
        visible: root.handlers.length === 0 && root.targetMime !== ""
        text: "No .desktop handlers advertise this mime type."
    }

    SettingNote { text: root.status }

    Process {
        id: defaultsProc
        command: ["bash", "-c",
            "for m in x-scheme-handler/http x-scheme-handler/mailto inode/directory text/plain image/png video/mp4 audio/mpeg; do " +
            "  d=$(xdg-mime query default \"$m\" 2>/dev/null); printf '%s\\t%s\\n' \"$m\" \"$d\"; done"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var p = line.split("\t")
                if (p.length < 2) return
                var next = {}
                for (var k in root.defaults) next[k] = root.defaults[k]
                next[p[0]] = p[1]
                root.defaults = next
            }
        }
    }

    Process {
        id: handlersProc
        command: []
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var p = line.split("\t")
                if (p.length < 2) return
                var next = root.handlers.slice()
                next.push({ name: p[0], file: p[1] })
                root.handlers = next
            }
        }
    }

    Process { id: setProc; command: []; running: false; onExited: root.refresh() }
}
