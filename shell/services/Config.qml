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
    readonly property string configPath: _configHome + "/pill/config.json"
    // Pre-rename location; migrated once on first load.
    readonly property string legacyConfigPath: _configHome + "/bubbles/config.json"

    // Directories and external config paths.
    property string wallpaperDir: _home + "/Pictures/Wallpapers"
    property string recordingDir: _home + "/Videos/Recordings"
    property string screenshotDir: _home + "/Pictures/Screenshots"
    property string cavaConfig: _configHome + "/cava/quickshell.conf"

    // Session commands. Compositor-neutral defaults; override per-compositor
    // (e.g. hyprland's `hyprctl dispatch exit`) via ~/.config/pill/config.json.
    property var sessionLock: ["loginctl", "lock-session"]
    property var sessionLogout: ["sh", "-c", "loginctl terminate-user \"$USER\""]
    property var sessionSuspend: ["systemctl", "suspend"]
    property var sessionShutdown: ["systemctl", "poweroff"]
    property var sessionHibernate: ["systemctl", "hibernate"]
    property var sessionReboot: ["systemctl", "reboot"]

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
    // Eyes dance to a playing track wherever they appear (Settings → Bar).
    property bool eyesDance: true
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
    // Explicit lock/sign-in wallpaper (library path); empty = follow the
    // desktop wallpaper. Picked in the wallpaper panel with L / "Set lock".
    property string lockWallpaperPath: ""
    property bool lockPattern: true
    // Lock/sign-in pattern overlay: empty = follow the panel pattern above.
    property string lockPatternStyle: ""
    property string lockPatternDensity: ""
    readonly property string effectiveLockPatternStyle: lockPatternStyle || patternStyle
    readonly property string effectiveLockPatternDensity: lockPatternDensity || patternDensity
    // Rewrite ~/.config/fastfetch/config.jsonc from the palette on theme change.
    property bool fastfetchEnabled: true
    // Logo: "auto", "none", a builtin name (arch, cachyos, …), "small:<name>",
    // or a file path.
    property string fastfetchLogo: "auto"
    // Comma-separated fastfetch modules in output order; empty = the built-in
    // default set. Edited through the module picker (Settings → Fastfetch).
    property string fastfetchModules: ""
    // fastfetch key labels: string (labels) | both | icon | none.
    property string fastfetchKeyType: "string"
    // Long key names: "Window Manager" instead of "WM".
    property bool fastfetchVerboseKeys: false

    // Position on screen: "top" | "bottom"
    property string position: "top"

    // Clock display: "12" (default, matches the original pill clock) or "24".
    property string clockFormat: "12"

    // Collapsed pill status slot (Settings → Bar):
    // ram | cpu | disk | battery | volume | brightness | network | none.
    property string idleMonitor: "ram"

    // Collapsed pill while media plays: cava | face | both.
    property string idlePlaying: "cava"

    // Expanded pill status tray.
    property bool trayWifi: true
    property bool trayBluetooth: true
    property bool trayBattery: true
    property bool trayDnd: true
    property bool trayAudio: true
    property bool trayMic: true
    property bool trayRecording: true

    // Dynamic theming is owned by ~/.config/wallust/wallust.toml (backend,
    // palette, colour space…); Pill maps whatever wallust generates.

    // ponytail: one key list drives _apply + _collect — add a prop here once.
    readonly property var _keys: ["pinned", "pinMode", "wallpaperDir", "recordingDir", "screenshotDir", "cavaConfig", "autoHideDelay", "showDelay", "maxNotifications", "notificationTimeout", "osdTimeout", "fontFamily", "iconFontFamily", "position", "fontScale", "eyesEnabled", "eyesDance", "eyeVariant", "syncSystemTheme", "patternStyle", "patternDensity", "lockWallpaper", "lockWallpaperPath", "lockPattern", "lockPatternStyle", "lockPatternDensity", "fastfetchEnabled", "fastfetchLogo", "fastfetchModules", "fastfetchKeyType", "fastfetchVerboseKeys", "clockFormat", "idleMonitor", "idlePlaying", "trayWifi", "trayBluetooth", "trayBattery", "trayDnd", "trayAudio", "trayMic", "trayRecording"]
    readonly property var _cmdKeys: ["sessionLock", "sessionSuspend", "sessionLogout", "sessionShutdown", "sessionHibernate", "sessionReboot"]

    function load(): void {
        loadCmd.run();
    }

    function _apply(data): void {
        for (var i = 0; i < _keys.length; i++)
            if (data[_keys[i]] !== undefined)
                root[_keys[i]] = data[_keys[i]];
        for (var j = 0; j < _cmdKeys.length; j++)
            if (Array.isArray(data[_cmdKeys[j]]))
                root[_cmdKeys[j]] = data[_cmdKeys[j]];
    }

    function _collect(): string {
        var out = {};
        for (var i = 0; i < _keys.length; i++)
            out[_keys[i]] = root[_keys[i]];
        for (var j = 0; j < _cmdKeys.length; j++)
            out[_cmdKeys[j]] = root[_cmdKeys[j]];
        return JSON.stringify(out, null, 2);
    }

    // The one mutation path: assign + debounced persist. Reads stay plain
    // property access; user actions call set() instead of assigning + save().
    function set(key, value): void {
        if (_keys.indexOf(key) === -1 && _cmdKeys.indexOf(key) === -1) {
            console.warn("Config.set: unknown key", key);
            return;
        }
        root[key] = value;
        saveTimer.restart();
    }

    function save(): void {
        saveCmd.command = ["sh", "-c", Store.saveCommand(root.configPath, root._collect())];
        saveCmd.run();
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
        onLine: function (line) {
            var data = Store.parse(line);
            if (data)
                root._apply(data);
        }
    }

    Cmd {
        id: saveCmd
        autorun: false
    }

    Component.onCompleted: root.load()
}
