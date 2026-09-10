pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import "../utils/shquote.js" as Sh

Item {
    id: root

    // Pin the bar so it never auto-hides.
    property bool pinned: false

    // Pin mode: "overlay" floats above windows; "bar" reserves screen space.
    property string pinMode: "overlay"

    readonly property string _home: Quickshell.env("HOME") || ("/home/" + (Quickshell.env("USER") || "user"))
    readonly property string _configHome: Quickshell.env("XDG_CONFIG_HOME") || (_home + "/.config")

    // User overrides file. Edit this instead of the repo file to keep settings across updates.
    readonly property string configPath: _configHome + "/pill/config.json"

    // Directories and external config paths.
    property string wallpaperDir: _home + "/Pictures/Wallpapers"
    property string recordingDir: _home + "/Videos/Recordings"
    property string screenshotDir: _home + "/Pictures/Screenshots"
    property string cavaConfig: _configHome + "/cava/quickshell.conf"

    // Session commands. Compositor-neutral defaults; override per-compositor
    // (e.g. hyprland's `hyprctl dispatch exit`) via ~/.config/pill/config.json.
    property var sessionLock:   ["loginctl", "lock-session"]
    property var sessionLogout:   ["sh", "-c", "loginctl terminate-user \"$USER\""]
    property var sessionSuspend: ["systemctl", "suspend"]
    property var sessionShutdown: ["systemctl", "poweroff"]
    property var sessionHibernate:["systemctl", "hibernate"]
    property var sessionReboot:   ["systemctl", "reboot"]

    // Auto-hide behaviour (ms).
    property int autoHideDelay: 1200
    property int showDelay: 100

    // Limits.
    property int maxNotifications: 50
    property int notificationTimeout: 3000
    property int osdTimeout: 1500

    // Appearance.
    property string fontFamily: ""
    property string iconFontFamily: "JetBrains Mono"
    property real fontScale: 1.0

    // Position on screen: "top" | "bottom" 
    property string position: "top"

    // Dynamic theming (matugen).
    property string themeMode: "auto"        // "auto" | "light" | "dark"
    property string themeVariant: "scheme-content" // matugen --type
    property string themePrefer: "lightness" // matugen --prefer
    property int themeAutoThreshold: 50      // brightness 0-100; > threshold = light

    // ponytail: one key list drives _apply + _collect — add a prop here once.
    readonly property var _keys: ["pinned", "pinMode", "wallpaperDir",
        "recordingDir", "screenshotDir", "cavaConfig", "autoHideDelay",
        "showDelay", "maxNotifications", "notificationTimeout", "osdTimeout",
        "fontFamily", "iconFontFamily", "position", "fontScale", "themeMode",
        "themeVariant", "themePrefer", "themeAutoThreshold"]
    readonly property var _cmdKeys: ["sessionLock", "sessionSuspend",
        "sessionLogout", "sessionShutdown", "sessionHibernate", "sessionReboot"]

    function load(): void {
        loadProc.running = true
    }

    function _apply(data): void {
        for (var i = 0; i < _keys.length; i++)
            if (data[_keys[i]] !== undefined) root[_keys[i]] = data[_keys[i]]
        for (var j = 0; j < _cmdKeys.length; j++)
            if (Array.isArray(data[_cmdKeys[j]])) root[_cmdKeys[j]] = data[_cmdKeys[j]]
    }

    function _collect(): string {
        var out = {}
        for (var i = 0; i < _keys.length; i++) out[_keys[i]] = root[_keys[i]]
        for (var j = 0; j < _cmdKeys.length; j++) out[_cmdKeys[j]] = root[_cmdKeys[j]]
        return JSON.stringify(out, null, 2)
    }

    property bool _pendingSave: false

    function save(): void {
        if (saveProc.running) {
            _pendingSave = true
            return
        }
        saveProc.command = ["sh", "-c",
            "mkdir -p " + Sh.q(root._configHome + "/pill") +
            " && cat > " + Sh.q(root.configPath) + " << 'OPCODE'\n" +
            root._collect() + "\nOPCODE"]
        saveProc.running = true
    }

    Process {
        id: loadProc
        command: ["bash", "-c", "jq -c . " + Sh.q(root.configPath) + " 2>/dev/null || true"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (!line.trim()) return
                try {
                    const data = JSON.parse(line)
                    root._apply(data)
                } catch (e) {
                    console.warn("Config: failed to parse config.json:", e)
                }
            }
        }
    }

    Process {
        id: saveProc
        command: []
        running: false
        onRunningChanged: {
            if (!running && _pendingSave) {
                _pendingSave = false
                save()
            }
        }
    }

    Component.onCompleted: root.load()
}
