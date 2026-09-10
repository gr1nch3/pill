pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import "../services"
import "../utils/shquote.js" as Sh

Item {
    id: root

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string themePath: stateDir + "/pill/theme.json"

    property string currentTheme: "dynamic"
    property string themeMode: Config.themeMode
    property string themeVariant: Config.themeVariant

    readonly property string _systemFont: Qt.application.font.family

    readonly property QtObject font: QtObject {
        property string family: Config.fontFamily !== "" ? Config.fontFamily : root._systemFont
        property string mono: Config.iconFontFamily
        property QtObject size: QtObject {
            property real scale: Config.fontScale
            property int caption: Math.round(9 * scale)
            property int small: Math.round(11 * scale)
            property int normal: Math.round(13 * scale)
            property int large: Math.round(16 * scale)
            property int xlarge: Math.round(20 * scale)
        }
    }

    readonly property var availableVariants: [
        { name: "scheme-content", label: "Content" },
        { name: "scheme-expressive", label: "Expressive" },
        { name: "scheme-fidelity", label: "Fidelity" },
        { name: "scheme-fruit-salad", label: "Fruit" },
        { name: "scheme-monochrome", label: "Mono" },
        { name: "scheme-neutral", label: "Neutral" },
        { name: "scheme-rainbow", label: "Rainbow" },
        { name: "scheme-tonal-spot", label: "Tonal" },
        { name: "scheme-vibrant", label: "Vibrant" }
    ]

    function themeByName(name) {
        for (var i = 0; i < themes.length; i++) {
            if (themes[i].name === name) return themes[i];
        }
        return null;
    }

    function applyTheme() {
        if (currentTheme === "dynamic") {
            Wallpaper.refreshThemes();
        } else {
            var t = themeByName(currentTheme);
            if (t && t.source) {
                Wallpaper.applyThemeSource(t.name, t.source, t.mode || themeMode);
            }
        }
    }

    function setTheme(name) {
        currentTheme = name;
        save();
        applyTheme();
    }

    function setMode(mode) {
        themeMode = mode;
        save();
        if (currentTheme === "dynamic") Wallpaper.regenerate();
    }

    function setVariant(variant) {
        themeVariant = variant;
        save();
        if (currentTheme === "dynamic") Wallpaper.regenerate();
    }

    function nextTheme() {
        var names = themes.map(t => t.name);
        var idx = names.indexOf(currentTheme);
        currentTheme = names[(idx + 1) % names.length];
        save();
        applyTheme();
    }

    function save() {
        const payload = JSON.stringify({
            theme: currentTheme,
            mode: themeMode,
            variant: themeVariant
        });
        saveProc.command = ["bash", "-c",
            "mkdir -p " + Sh.q(stateDir + "/pill") +
            " && printf '%s' " + Sh.q(payload) + " > " + Sh.q(themePath)
        ];
        saveProc.running = true;
        snapshotTimer.restart();
    }

    function load() {
        loadProc.running = true;
    }

    Process {
        id: loadProc
        command: ["jq", "-c", ".", root.themePath]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    const data = JSON.parse(line);
                    if (data.theme) root.currentTheme = data.theme;
                    if (data.mode) root.themeMode = data.mode;
                    if (data.variant) root.themeVariant = data.variant;
                    root.applyTheme();
                    // Dynamic palettes resolve async; give ThemeEngine a beat.
                    snapshotTimer.restart();
                } catch (e) {
                    console.warn("Theme: failed to parse persisted theme:", e);
                }
            }
        }
    }

    Process {
        id: saveProc
        command: []; running: false
    }

    Timer {
        id: snapshotTimer
        interval: 800
        onTriggered: root.writeGreeterSnapshot()
    }

    Component.onCompleted: root.load()

    readonly property var themes: [
        {
            name: "dynamic",
            label: "Dynamic",
            source: "",
            mode: "",
            background:   ThemeEngine.loaded ? ThemeEngine.palette.background : themeMode === "light" ? "#f0f0f0" : "#0b0b10",
            surface:      ThemeEngine.loaded ? ThemeEngine.palette.surface : themeMode === "light" ? "#e0e0e0" : "#15151a",
            surfaceHover: ThemeEngine.loaded ? ThemeEngine.palette.surfaceHover : themeMode === "light" ? "#d0d0d0" : "#1f1f28",
            highlight:    ThemeEngine.loaded ? ThemeEngine.palette.highlight : themeMode === "light" ? "#c0c0c0" : "#2a2a35",
            accent:       ThemeEngine.loaded ? ThemeEngine.palette.accent : "#4ecdc4",
            accentAlt:    ThemeEngine.loaded ? ThemeEngine.palette.accentAlt : "#7fdbda",
            text:         ThemeEngine.loaded ? ThemeEngine.palette.text : themeMode === "light" ? "#1a1a1a" : "#f0f0f5",
            subtext:      ThemeEngine.loaded ? ThemeEngine.palette.subtext : "#8a8a99",
            danger:       ThemeEngine.loaded ? ThemeEngine.palette.danger : "#ff6b6b",
            dangerBg:     ThemeEngine.loaded ? ThemeEngine.palette.dangerBg : "#2a1515",
            dangerHover:  ThemeEngine.loaded ? ThemeEngine.palette.dangerHover : "#3d1e1e",
            border:       ThemeEngine.loaded ? ThemeEngine.palette.border : "#28a8a899"
        },
        {
            name: "ariadne",
            label: "ariadne",
            source: "#4ecdc4",
            mode: "dark",
            background:   "#0b0b10",
            surface:      "#15151a",
            surfaceHover: "#1f1f28",
            highlight:    "#2a2a35",
            accent:       "#4ecdc4",
            accentAlt:    "#7fdbda",
            text:         "#f0f0f5",
            subtext:      "#8a8a99",
            danger:       "#ff6b6b",
            dangerBg:     "#2a1515",
            dangerHover:  "#3d1e1e",
            border:       "#28a8a899"
        },
        {
            name: "gruvbox",
            label: "Gruvbox",
            source: "#d79921",
            mode: "dark",
            background:   "#282828",
            surface:      "#3c3836",
            surfaceHover: "#504945",
            highlight:    "#665c54",
            accent:       "#d79921",
            accentAlt:    "#b57614",
            text:         "#ebdbb2",
            subtext:      "#a89984",
            danger:       "#cc241d",
            dangerBg:     "#3c1c1c",
            dangerHover:  "#4e2020",
            border:       "#44a89984"
        },
        {
            name: "catppuccin",
            label: "Catppuccin",
            source: "#cba6f7",
            mode: "dark",
            background:   "#1e1e2e",
            surface:      "#313244",
            surfaceHover: "#45475a",
            highlight:    "#585b70",
            accent:       "#cba6f7",
            accentAlt:    "#89b4fa",
            text:         "#cdd6f4",
            subtext:      "#a6adc8",
            danger:       "#f38ba8",
            dangerBg:     "#2c1e2e",
            dangerHover:  "#3d2040",
            border:       "#44a6adc8"
        },
        {
            name: "tokyonight",
            label: "Tokyo Night",
            source: "#7aa2f7",
            mode: "dark",
            background:   "#1a1b26",
            surface:      "#24283b",
            surfaceHover: "#2e3248",
            highlight:    "#3b4261",
            accent:       "#7aa2f7",
            accentAlt:    "#bb9af7",
            text:         "#c0caf5",
            subtext:      "#565f89",
            danger:       "#f7768e",
            dangerBg:     "#2a1520",
            dangerHover:  "#3d1e2e",
            border:       "#44565f89"
        },
        {
            name: "nord",
            label: "Nord",
            source: "#88c0d0",
            mode: "dark",
            background:   "#2e3440",
            surface:      "#3b4252",
            surfaceHover: "#434c5e",
            highlight:    "#4c566a",
            accent:       "#88c0d0",
            accentAlt:    "#81a1c1",
            text:         "#eceff4",
            subtext:      "#d8dee9",
            danger:       "#bf616a",
            dangerBg:     "#2d1f22",
            dangerHover:  "#3d2528",
            border:       "#444c566a"
        },
        {
            name: "rosepine",
            label: "Rosé Pine",
            source: "#eb6f92",
            mode: "dark",
            background:   "#191724",
            surface:      "#1f1d2e",
            surfaceHover: "#26233a",
            highlight:    "#403d52",
            accent:       "#eb6f92",
            accentAlt:    "#f6c177",
            text:         "#e0def4",
            subtext:      "#6e6a86",
            danger:       "#eb6f92",
            dangerBg:     "#2a1020",
            dangerHover:  "#3d1530",
            border:       "#446e6a86"
        },
        {
            name: "everforest",
            label: "Everforest",
            source: "#a7c080",
            mode: "dark",
            background:   "#272e33",
            surface:      "#2e383c",
            surfaceHover: "#374145",
            highlight:    "#414b50",
            accent:       "#a7c080",
            accentAlt:    "#83c092",
            text:         "#d3c6aa",
            subtext:      "#859289",
            danger:       "#e67e80",
            dangerBg:     "#2c1e1e",
            dangerHover:  "#3d2828",
            border:       "#44859289"
        }
    ]

    readonly property var _t: {
        if (currentTheme === "dynamic" && ThemeEngine.loaded && ThemeEngine.palette)
            return ThemeEngine.palette;
        for (var i = 0; i < themes.length; i++) {
            if (themes[i].name === currentTheme) return themes[i];
        }
        return themes[0];
    }

    readonly property color background:   _t.background
    readonly property color surface:      _t.surface
    readonly property color surfaceHover: _t.surfaceHover
    readonly property color highlight:    _t.highlight
    readonly property color accent:       _t.accent
    readonly property color accentAlt:    _t.accentAlt
    readonly property color text:         _t.text
    readonly property color subtext:      _t.subtext
    readonly property color danger:       _t.danger
    readonly property color dangerBg:     _t.dangerBg
    readonly property color dangerHover:  _t.dangerHover
    readonly property color border: {
        if (currentTheme === "dynamic" && ThemeEngine.loaded)
            return Qt.rgba(ThemeEngine.outline.r, ThemeEngine.outline.g, ThemeEngine.outline.b, 0.35);
        return _t.border;
    }

    // ── Eye identity palette (PRD §6.3) ─────────────────────────────────────
    // Derived from the active theme's own static table — fixed themes never
    // touch matugen; dynamic derives live from ThemeEngine via _t.
    readonly property var eyeMoods: ({
        idle:   { color: _t.subtext, opacity: 0.55 },
        active: { color: _t.accent, opacity: 1.0 },
        alert:  { color: "#f0a500", opacity: 1.0 },
        error:  { color: _t.danger, opacity: 1.0 }
    })

    // ── Greeter palette snapshot (PRD §6.5) ─────────────────────────────────
    // SDDM runs pre-compositor and can't watch a live wallpaper daemon, so we
    // write the resolved palette to the user cache on every theme apply;
    // `bubbles theme`/`update` escalate a copy to /etc/xdg/bubbles/ (ryoku §5:
    // user pref first, honest message if escalation is cancelled).
    // ponytail: dynamic wallpaper changes don't re-snapshot until the next
    // theme/save — run `bubbles theme dynamic` after switching wallpapers.
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/bubbles"

    function writeGreeterSnapshot() {
        const hex = function(c) {
            const s = "" + c
            return s.length === 9 ? "#" + s.slice(3) : s   // strip #AARRGGBB alpha
        }
        const payload = JSON.stringify({
            background: hex(background),
            surface: hex(surface),
            accent: hex(accent),
            text: hex(text),
            subtext: hex(subtext),
            danger: hex(danger),
            border: hex(border)
        })
        snapshotProc.command = ["bash", "-c",
            "mkdir -p " + Sh.q(cacheDir) +
            " && printf '%s' " + Sh.q(payload) + " > " + Sh.q(cacheDir + "/greeter-palette.json")]
        snapshotProc.running = true
    }

    Process {
        id: snapshotProc
        command: []; running: false
    }
}
