pragma Singleton
// Hyprland runtime options + monitor rules via hyprctl. Nothing here touches
// the user's Hyprland config files: writes are runtime-only (`hyprctl
// keyword`) and re-applied from ~/.config/bubbles/{hypr,monitors}.json when
// the shell starts. Inert off Hyprland: `available`/`monitorsAvailable` stay
// false and the pages show "not detected".
import QtQuick
import Quickshell

import "../utils"
import "../utils/shquote.js" as Sh

Item {
    id: root

    readonly property string _home: Quickshell.env("HOME") || ""
    readonly property string _configHome: Quickshell.env("XDG_CONFIG_HOME") || (_home + "/.config")
    readonly property string persistPath: _configHome + "/bubbles/hypr.json"
    readonly property string legacyPersistPath: _configHome + "/pill/hypr.json"
    readonly property string monitorsPersistPath: _configHome + "/bubbles/monitors.json"
    readonly property string legacyMonitorsPersistPath: _configHome + "/pill/monitors.json"

    // ── Options ────────────────────────────────────────────────────────────
    property bool available: false
    property var values: ({})
    property var _saved: ({})

    function value(key) { return values[key] }

    function setOption(key, value) {
        var next = {}
        for (var k in values) next[k] = values[k]
        next[key] = value
        values = next
        writeCmd.command = ["hyprctl", "keyword", key, typeof value === "boolean" ? (value ? "true" : "false") : String(value)]
        writeCmd.run()
        saveOptions()
    }

    function toggleOption(key) { setOption(key, !values[key]) }

    function saveOptions() {
        saveCmd.command = ["sh", "-c", Store.saveCommand(persistPath, JSON.stringify(values))]
        saveCmd.run()
    }

    // Pages pass the keys they render; keeps the schema out of the service.
    function readOptions(keys) {
        if (!keys || keys.length === 0) return
        var list = []
        for (var i = 0; i < keys.length; i++) list.push(Sh.q(keys[i]))
        readCmd.command = ["bash", "-c",
            "command -v hyprctl >/dev/null 2>&1 || { echo UNAVAILABLE; exit 0; }\n" +
            "for k in " + list.join(" ") + "; do\n" +
            "  v=$(hyprctl -j getoption \"$k\" 2>/dev/null) || { echo UNAVAILABLE; exit 0; }\n" +
            "  printf '%s\\t%s\\n' \"$k\" \"$v\"\n" +
            "done"]
        readCmd.run()
    }

    function _valueOf(o) {
        if (typeof o.bool === "boolean") return o.bool
        if (typeof o.int === "number") return o.int
        if (typeof o.float === "number") return o.float
        if (typeof o.str === "string") return o.str
        // gaps_* are css "t t b b" in Hyprland 0.56; use the first token.
        if (typeof o.css === "string") {
            var n = parseFloat(o.css)
            if (!isNaN(n)) return n
        }
        return undefined
    }

    Cmd {
        id: readCmd
        autorun: false
        onLine: function(line) {
            var text = line.trim()
            if (text === "UNAVAILABLE") { root.available = false; return }
            var tab = text.indexOf("\t")
            if (tab < 0) return
            try {
                var obj = JSON.parse(text.slice(tab + 1))
                var v = root._valueOf(obj)
                if (v === undefined) return
                var next = {}
                for (var k in root.values) next[k] = root.values[k]
                next[text.slice(0, tab)] = v
                root.values = next
                root.available = true
            } catch (e) {
                console.warn("Hyprland: bad getoption output:", text)
            }
        }
    }

    Cmd { id: writeCmd; autorun: false }
    Cmd { id: saveCmd; autorun: false }

    // Startup: read saved keys, re-apply them; pages read live values on open.
    property string _buf: ""

    Cmd {
        id: loadCmd
        command: ["bash", "-c", Store.loadCommand(root.persistPath, root.legacyPersistPath)]
        autorun: false
        onLine: function(line) { root._buf += line }
        onDone: {
            root._saved = Store.parse(root._buf) || ({})
            root._buf = ""
            root._applySavedOptions()
        }
    }

    function _applySavedOptions() {
        var lines = []
        for (var k in _saved) {
            var v = _saved[k]
            lines.push("hyprctl keyword " + Sh.q(k) + " " +
                Sh.q(typeof v === "boolean" ? (v ? "true" : "false") : String(v)) +
                " >/dev/null 2>&1 || true")
        }
        if (lines.length === 0) return
        applyCmd.command = ["bash", "-c",
            "command -v hyprctl >/dev/null 2>&1 || exit 0\n" + lines.join("\n")]
        applyCmd.run()
    }

    Cmd { id: applyCmd; autorun: false }

    // Availability probe: hyprctl present and answering IPC.
    Cmd {
        command: ["bash", "-c", "command -v hyprctl >/dev/null 2>&1 && hyprctl -j monitors >/dev/null 2>&1 && echo OK || echo NO"]
        onLine: function(line) { root.available = line.trim() === "OK" }
    }

    // ── Monitors ───────────────────────────────────────────────────────────
    property var monitors: []
    property bool monitorsAvailable: false
    property string monitorsError: ""
    property var _savedMonitors: ({})

    function refreshMonitors() { listCmd.run() }

    function _posOf(m) {
        // -1/-1 is Hyprland's "unset"; never bake that into a rule.
        if (Number(m.x) < 0 && Number(m.y) < 0) return "auto"
        return Math.round(m.x) + "x" + Math.round(m.y)
    }

    function setMonitorMode(name, mode) {
        var m = _findMonitor(name)
        if (!m) return
        _writeMonitor(_rule(name, mode, _posOf(m), m.scale, m.transform))
        _rememberMonitor(name, mode, _posOf(m), m.scale, m.transform)
    }

    function setMonitorScale(name, scale) {
        var m = _findMonitor(name)
        if (!m) return
        _writeMonitor(_rule(name, _monitorMode(m), _posOf(m), scale, m.transform))
        _rememberMonitor(name, _monitorMode(m), _posOf(m), scale, m.transform)
    }

    function setMonitorTransform(name, transform) {
        var m = _findMonitor(name)
        if (!m) return
        _writeMonitor(_rule(name, _monitorMode(m), _posOf(m), m.scale, transform))
        _rememberMonitor(name, _monitorMode(m), _posOf(m), m.scale, transform)
    }

    // Arrange canvas: absolute layout position, "x y" in Hyprland's rule.
    function setMonitorPosition(name, x, y) {
        var m = _findMonitor(name)
        if (!m) return
        var pos = Math.round(x) + "x" + Math.round(y)
        _writeMonitor(_rule(name, _monitorMode(m), pos, m.scale, m.transform))
        _rememberMonitor(name, _monitorMode(m), pos, m.scale, m.transform)
    }

    function _monitorMode(m) {
        return m.width + "x" + m.height + "@" + Number(m.refreshRate).toFixed(2)
    }

    function _rule(name, mode, pos, scale, transform) {
        var s = name + "," + mode + "," + (pos || "auto") + "," + scale
        if (transform && Number(transform) !== 0) s += "," + transform
        return s
    }

    function _findMonitor(name) {
        for (var i = 0; i < root.monitors.length; i++)
            if (root.monitors[i].name === name) return root.monitors[i]
        return null
    }

    function _writeMonitor(rule) {
        if (!Integrations.has("hyprctl")) return
        monitorWriteCmd.command = ["hyprctl", "keyword", "monitor", rule]
        monitorWriteCmd.run()
    }

    function _rememberMonitor(name, mode, pos, scale, transform) {
        var next = {}
        for (var k in _savedMonitors) next[k] = _savedMonitors[k]
        next[name] = { mode: mode, pos: pos, scale: scale, transform: transform }
        _savedMonitors = next
        monitorSaveCmd.command = ["sh", "-c", Store.saveCommand(monitorsPersistPath, JSON.stringify(next))]
        monitorSaveCmd.run()
    }

    property string _monBuf: ""
    Cmd {
        id: listCmd
        command: ["bash", "-c",
            "command -v hyprctl >/dev/null 2>&1 || { echo '[]'; exit 0; }\nhyprctl -j monitors 2>/dev/null || echo '[]'"]
        autorun: false
        onLine: function(line) { root._monBuf += line }
        onDone: {
            var arr = Store.parse(root._monBuf)
            if (arr) {
                root.monitors = arr
                root.monitorsAvailable = arr.length > 0
            } else {
                root.monitorsAvailable = false
                root.monitorsError = "bad monitors output"
            }
            root._monBuf = ""
        }
    }

    Cmd { id: monitorWriteCmd; autorun: false }
    Cmd { id: monitorSaveCmd; autorun: false }

    Cmd {
        id: monitorLoadCmd
        command: ["bash", "-c", Store.loadCommand(root.monitorsPersistPath, root.legacyMonitorsPersistPath)]
        autorun: false
        onLine: function(line) {
            var data = Store.parse(line)
            root._savedMonitors = data || ({})
        }
        onDone: root._applySavedMonitors()
    }

    function _applySavedMonitors() {
        var lines = []
        for (var name in _savedMonitors) {
            var v = _savedMonitors[name]
            lines.push("hyprctl keyword monitor " + Sh.q(_rule(name, v.mode, v.pos || "auto", v.scale, v.transform)) + " >/dev/null 2>&1 || true")
        }
        if (lines.length === 0 || !Integrations.has("hyprctl")) {
            root.refreshMonitors()
            return
        }
        monitorApplyCmd.command = ["bash", "-c", lines.join("\n")]
        monitorApplyCmd.run()
    }

    Cmd {
        id: monitorApplyCmd
        autorun: false
        onDone: root.refreshMonitors()
    }

    Component.onCompleted: {
        loadCmd.run()
        Integrations.whenReady(function() { monitorLoadCmd.run() })
    }
}
