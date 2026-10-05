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
    property var _handlerBuf: []
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
        targetMime = mime
        handlers = []
        _handlerBuf = []
        handlersProc.command = ["bash", "-c",
            "for f in /usr/share/applications/*.desktop \"$HOME\"/.local/share/applications/*.desktop; do\n" +
            "  [ -f \"$f\" ] || continue\n" +
            "  grep -q \"^MimeType=.*" + mime + "\" \"$f\" 2>/dev/null || continue\n" +
            "  name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-)\n" +
            "  printf '%s\\t%s\\n' \"$name\" \"$f\"\n" +
            "done | sort -u | head -16"]
        handlersProc.running = true
        handlerDialog.open()
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
                label: "Change"
                onClicked: root.openHandlers(appRow.modelData.mime)
            }
        }
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
            // accumulate: one assignment per query instead of a row rebuild
            // per output line while the dialog is opening
            onRead: function(line) {
                var p = line.split("\t")
                if (p.length < 2) return
                root._handlerBuf.push({ name: p[0], file: p[1] })
            }
        }
        onExited: {
            root.handlers = root._handlerBuf
            root._handlerBuf = []
        }
    }

    Process { id: setProc; command: []; running: false; onExited: root.refresh() }

    // The handler catalogue (up to 16 entries) only matters while choosing:
    // a dialog keeps the page from growing an inline list.
    SettingDialog {
        id: handlerDialog
        title: "Open with"
        description: "Pick the default handler for " + root.targetMime + "."

        ListView {
            id: handlerList
            width: parent.width
            height: Math.min(contentHeight, 280)
            clip: true
            model: root.handlers
            spacing: 2

            delegate: Rectangle {
                id: handlerRow
                required property var modelData
                width: handlerList.width
                height: 38
                radius: Theme.shape.radius.hairline
                color: handlerMouse.containsMouse ? Theme.surfaceHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                Column {
                    anchors { left: parent.left; leftMargin: 10; right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 1

                    Text {
                        width: parent.width
                        text: handlerRow.modelData.name
                        color: Theme.text
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                        font.weight: 500
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: handlerRow.modelData.file.split("/").pop()
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.caption
                        font.family: Theme.font.mono
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: handlerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.setDefault(root.targetMime, handlerRow.modelData.file)
                        handlerDialog.close()
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.handlers.length === 0
            text: "Loading handlers…"
            color: Theme.subtext
            font.pixelSize: Theme.font.size.caption
            font.family: Theme.font.family
        }

        Item {
            width: parent.width
            height: 30

            Row {
                anchors.right: parent.right
                spacing: 8
                SettingAction { label: "Cancel"; onClicked: handlerDialog.close() }
            }
        }
    }
}
