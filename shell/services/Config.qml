pragma Singleton
import QtQuick
import Quickshell

import "../utils"

Item {
    id: root

    // Pin the bar so it never auto-hides.
    property bool pinned: false

    // Pin mode: "overlay" floats above windows; "bar" reserves screen space.
    property string pinMode: "overlay"

    readonly property string _home: Quickshell.env("HOME") || ("/home/" + (Quickshell.env("USER") || "user"))
    readonly property string _configHome: Quickshell.env("XDG_CONFIG_HOME") || (_home + "/.config")

    // User overrides file. Edit this instead of the repo file to keep settings across updates.
    readonly property string configPath: _configHome + "/bubbles/config.json"
    // Pre-rename location; migrated once on first load.
    readonly property string legacyConfigPath: _configHome + "/pill/config.json"

    // Directories and external config paths.
    property string wallpaperDir: _home + "/Pictures/Wallpapers"
    property string recordingDir: _home + "/Videos/Recordings"
    property string screenshotDir: _home + "/Pictures/Screenshots"
    property string cavaConfig: _configHome + "/cava/quickshell.conf"

    // Session commands. Compositor-neutral defaults; override per-compositor
    // (e.g. hyprland's `hyprctl dispatch exit`) via ~/.config/bubbles/config.json.
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
    // Show the robot face in pill headers. Toggle lives in Settings → Bar.
    property bool eyesEnabled: true
    // Expression shape: normal | angry | sad | surprised | sleepy.
    property string eyeVariant: "normal"
    // Mirror the resolved palette to GTK/Qt/gsettings on every theme change.
    property bool syncSystemTheme: true
    // Background patterns behind large panels: none | dots | grid | diagonal |
    // cross | chevron | noise.
    property string patternStyle: "dots"
    // Pattern pitch: sparse | normal | dense.
    property string patternDensity: "normal"
    // Lock screen / sign-in screen background: current wallpaper (gif/video
    // stills included) and the pattern overlay.
    property bool lockWallpaper: true
    property bool lockPattern: true
    // Rewrite ~/.config/fastfetch/config.jsonc from the palette on theme change.
    property bool fastfetchEnabled: true
    // Logo: "auto", "none", a builtin name (arch, cachyos, …), "small:<name>",
    // or a file path.
    property string fastfetchLogo: "auto"
    // Comma-separated fastfetch modules; empty = the built-in default set.
    property string fastfetchModules: ""

    // Position on screen: "top" | "bottom" 
    property string position: "top"

    // Clock display: "12" (default, matches the original pill clock) or "24".
    property string clockFormat: "12"

    // Dynamic theming (matugen).
    property string themeMode: "auto"        // "auto" | "light" | "dark"
    property string themeVariant: "scheme-content" // matugen --type
    property string themePrefer: "lightness" // matugen --prefer
    property int themeAutoThreshold: 50      // brightness 0-100; > threshold = light

    // ponytail: one key list drives _apply + _collect — add a prop here once.
    readonly property var _keys: ["pinned", "pinMode", "wallpaperDir",
        "recordingDir", "screenshotDir", "cavaConfig", "autoHideDelay",
        "showDelay", "maxNotifications", "notificationTimeout", "osdTimeout",
        "fontFamily", "iconFontFamily", "position", "fontScale", "eyesEnabled",
        "eyeVariant", "syncSystemTheme", "patternStyle", "patternDensity",
        "lockWallpaper", "lockPattern",
        "fastfetchEnabled", "fastfetchLogo",
        "fastfetchModules", "clockFormat", "themeMode", "themeVariant",
        "themePrefer", "themeAutoThreshold"]
    readonly property var _cmdKeys: ["sessionLock", "sessionSuspend",
        "sessionLogout", "sessionShutdown", "sessionHibernate", "sessionReboot"]

    function load(): void {
        loadCmd.run()
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

    // The one mutation path: assign + debounced persist. Reads stay plain
    // property access; user actions call set() instead of assigning + save().
    function set(key, value): void {
        if (_keys.indexOf(key) === -1 && _cmdKeys.indexOf(key) === -1) {
            console.warn("Config.set: unknown key", key)
            return
        }
        root[key] = value
        saveTimer.restart()
    }

    function save(): void {
        saveCmd.command = ["sh", "-c", Store.saveCommand(root.configPath, root._collect())]
        saveCmd.run()
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: root.save()
    }

    Cmd {
        id: loadCmd
        command: ["bash", "-c", Store.loadCommand(root.configPath, root.legacyConfigPath)]
        autorun: false
        onLine: function(line) {
            var data = Store.parse(line)
            if (data) root._apply(data)
        }
    }

    Cmd {
        id: saveCmd
        autorun: false
    }

    Component.onCompleted: root.load()
}
