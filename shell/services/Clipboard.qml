pragma Singleton
// Clipboard history over cliphist. Views call refresh()/copy(id); parsing,
// mime detection and the decode|wl-copy pipeline stay here.
import QtQuick

import "../utils"
import "../utils/shquote.js" as Sh

Item {
    id: root

    // [{ id, text, mime }]
    property var entries: []
    property bool scanning: false
    property var _buffer: []

    function refresh() {
        root.entries = []
        root.scanning = true
        listCmd.run()
    }

    function find(id) {
        for (var i = 0; i < root.entries.length; i++)
            if (root.entries[i].id === id) return root.entries[i]
        return null
    }

    function copy(id) {
        var entry = find(id)
        if (!entry) return
        var cmd = "cliphist decode " + Sh.q(entry.id) + " | wl-copy"
        if (entry.mime) cmd += " --type " + Sh.q(entry.mime)
        copyCmd.command = ["sh", "-c", cmd]
        copyCmd.run()
    }

    function _mimeForExt(ext) {
        var known = {
            png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg",
            gif: "image/gif", webp: "image/webp", bmp: "image/bmp"
        }
        return known[ext] || "application/octet-stream"
    }

    Cmd {
        id: listCmd
        command: ["sh", "-c", "cliphist list | head -1000"]
        autorun: false
        onLine: function(line) {
            var trimmed = line.trim()
            if (trimmed === "") return
            var idx = trimmed.indexOf("\t")
            if (idx < 0) return
            var text = trimmed.substring(idx + 1)
            var entry = { id: trimmed.substring(0, idx), text: text, mime: "" }
            var bin = text.match(/\[\[ binary data .*? (\w+)(?: \d+x\d+)? \]\]/)
            if (bin) entry.mime = root._mimeForExt(bin[1])
            root._buffer.push(entry)
        }
        onDone: {
            root.entries = root._buffer.slice()
            root._buffer = []
            root.scanning = false
        }
    }

    Cmd { id: copyCmd; autorun: false }
}
