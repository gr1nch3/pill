pragma Singleton
// Owns theme selection, persistence, palette resolution and the apply
// pipeline: reload palette -> re-run wallust templates -> sync GTK/Qt.
// Wallpaper runs wallust itself (Wallpaper.qml); ThemeEngine stores the
// palette, SystemTheme writes system files; none of them know about each
// other.
import QtQuick
import Quickshell

import "../utils"
import "../utils/Themes.js" as Themes
import "../utils/shquote.js" as Sh

Item {
    id: root

    readonly property string _stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string themePath: _stateDir + "/pill/theme.json"
    readonly property string legacyThemePath: _stateDir + "/bubbles/theme.json"
    // A wallust colourscheme synthesized from the resolved palette; passed to
    // `wallust cs` so fixed themes retint apps too.
    readonly property string wallustSchemePath: _stateDir + "/pill/wallust-scheme.json"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/pill"

    property string currentTheme: "dynamic"
    // "" = use the active theme's own shape style.
    property string shapeStyle: ""
    property var userThemes: []
    // True only during the startup load; apply() then keeps the on-disk
    // scheme instead of re-deriving it (the autostart wallpaper set does).
    property bool _restoring: false
    // False until theme.json has been read: app templates must not be
    // re-rendered for the default theme before the saved one is known.
    property bool _themeLoaded: false

    // ── Palette resolution ────────────────────────────────────────────────
    function _dynamicEntry() {
        var p = ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette : Themes.dynamicFallback();
        return {
            name: "dynamic",
            label: "Dynamic",
            source: "",
            mode: "",
            background: p.background,
            surface: p.surface,
            surfaceHover: p.surfaceHover,
            highlight: p.highlight,
            accent: p.accent,
            accentAlt: p.accentAlt,
            text: p.text,
            subtext: p.subtext,
            danger: p.danger,
            dangerBg: p.dangerBg,
            dangerHover: p.dangerHover,
            border: p.border,
            shape: Themes.defaultShape,
            motion: Themes.defaultMotion
        };
    }

    readonly property var themes: {
        var out = [root._dynamicEntry()].concat(Themes.builtins.map(Themes.withStyle));
        for (var i = 0; i < root.userThemes.length; i++) {
            var u = root.userThemes[i];
            var replaced = false;
            for (var j = 0; j < out.length; j++) {
                if (out[j].name === u.name) {
                    out[j] = u;
                    replaced = true;
                    break;
                }
            }
            if (!replaced)
                out.push(u);
        }
        return out;
    }

    function themeByName(name) {
        for (var i = 0; i < root.themes.length; i++)
            if (root.themes[i].name === name)
                return root.themes[i];
        return null;
    }

    readonly property var _t: {
        if (root.currentTheme === "dynamic" && ThemeEngine.loaded && ThemeEngine.palette)
            return ThemeEngine.palette;
        for (var i = 0; i < root.themes.length; i++)
            if (root.themes[i].name === root.currentTheme)
                return root.themes[i];
        return root.themes[0];
    }

    readonly property color background: root._t.background
    readonly property color surface: root._t.surface
    readonly property color surfaceHover: root._t.surfaceHover
    readonly property color highlight: root._t.highlight
    readonly property color accent: root._t.accent
    readonly property color accentAlt: root._t.accentAlt
    readonly property color text: root._t.text
    readonly property color subtext: root._t.subtext
    readonly property color danger: root._t.danger
    readonly property color dangerBg: root._t.dangerBg
    readonly property color dangerHover: root._t.dangerHover
    // Fixed status inks (Themes.statusColors): errors reuse `danger`; warning
    // and success never follow the accent.
    readonly property color warning: Themes.statusColors.warning
    readonly property color success: Themes.statusColors.success
    readonly property color _themeBorder: root._t.border
    readonly property color border: {
        if (root.currentTheme === "dynamic" && ThemeEngine.loaded && ThemeEngine.palette)
            return Qt.rgba(root._themeBorder.r, root._themeBorder.g, root._themeBorder.b, 0.35);
        return root._themeBorder;
    }

    // ── Shape + motion tokens (per-theme, defaulted) ──────────────────────
    readonly property var shape: {
        var base = root._t.shape || Themes.defaultShape;
        if (root.shapeStyle === "")
            return base;
        return {
            style: root.shapeStyle,
            slant: base.slant,
            radius: base.radius,
            border: base.border
        };
    }
    readonly property var motion: root._t.motion || Themes.defaultMotion

    // ── Eye identity palette (PRD §6.3) ─────────────────────────────────────
    readonly property var eyeMoods: ({
            idle: {
                color: root._t.subtext,
                opacity: 0.55
            },
            active: {
                color: root._t.accent,
                opacity: 1.0
            },
            alert: {
                color: Themes.statusColors.warning,
                opacity: 1.0
            },
            error: {
                color: root._t.danger,
                opacity: 1.0
            }
        })

    // ── Pipeline status ───────────────────────────────────────────────────
    property bool lastOk: true
    property string lastError: ""

    function setTheme(name) {
        root.currentTheme = name;
        root.save();
        root.apply();
    }

    function setShape(style) {
        root.shapeStyle = style;
        root.save();
    }

    // Horizontal inset a polygon style needs so content fits the background.
    function shapeInset(w, h) {
        return Themes.shapeCut(root.shape.style, root.shape.slant, w, h);
    }

    function nextTheme() {
        var names = root.themes.map(t => t.name);
        var idx = names.indexOf(root.currentTheme);
        root.currentTheme = names[(idx + 1) % names.length];
        root.save();
        root.apply();
    }

    function apply() {
        if (root.currentTheme === "dynamic") {
            // Switching to dynamic re-derives the scheme from the current
            // wallpaper; restoring on startup keeps the scheme on disk and
            // just re-runs the templates over it.
            if (!root._restoring && Wallpaper.committedWallpaper)
                Wallpaper.regenerate();
            else
                root.reapplyTemplates();
            root.scheduleSystemTheme();
            return;
        }
        var t = root.themeByName(root.currentTheme);
        if (!t || !t.source)
            return;
        root.reapplyTemplates();
    }

    // Re-run the user's wallust templates with one synthesized scheme:
    // dynamic uses the wallpaper's raw scheme pushed through the readability
    // pass (wallpaper hues kept, darks lifted); fixed themes use their
    // resolved palette, so their apps can never follow the wallpaper.
    function reapplyTemplates() {
        if (!Integrations.has("wallust")) {
            // Tool probe still in flight: retry when it lands, or a startup
            // apply would silently keep the previous theme's app colours.
            if (!Integrations.ready) {
                Integrations.whenReady(function () {
                    root.reapplyTemplates();
                });
                return;
            }
            root.scheduleSystemTheme();
            return;
        }
        var scheme = root.currentTheme === "dynamic" ? Themes.readableWallust(ThemeEngine.raw) : null;
        if (!scheme)
            scheme = Themes.wallustFromPalette(root._t);
        templatesCmd.command = ["bash", "-c", Store.saveCommand(root.wallustSchemePath, JSON.stringify(scheme)) + "\n" + "exec wallust -q cs --format wallust " + Sh.q(root.wallustSchemePath)];
        templatesCmd.run();
    }

    Cmd {
        id: templatesCmd
        autorun: false
        onDone: function (code) {
            root.lastOk = code === 0;
            root.lastError = root.lastOk ? "" : ("wallust exit " + code);
            root.scheduleSystemTheme();
            snapshotTimer.restart();
        }
    }

    // ── Wallpaper hook ────────────────────────────────────────────────────
    function setWallpaper(path) {
        Wallpaper.set(path, root.currentTheme === "dynamic");
    }

    Connections {
        target: Wallpaper
        function onApplied(path) {
            // Only the dynamic theme follows the wallpaper; under a fixed
            // theme the render happened but palette and templates stay put.
            if (root.currentTheme !== "dynamic")
                return;
            ThemeEngine.reload();
        }
    }

    Connections {
        target: ThemeEngine
        // The scheme file is (re)read: the palette is resolved now, so render
        // the app templates from it. Wallpaper extraction skips templates
        // (`wallust run --skip-templates`); this is the only lane that writes
        // them, and it only ever hands the raw scheme to the dynamic theme.
        function onRefreshed() {
            if (!root._themeLoaded || root.currentTheme !== "dynamic")
                return;
            root.reapplyTemplates();
            snapshotTimer.restart();
        }
    }

    // ── Palette-derived side effects (only this module talks to them) ─────
    // Fastfetch rides the same schedule as the system theme: every apply /
    // preference change rewrites its config from the resolved palette.
    function scheduleSystemTheme() {
        SystemTheme.schedule();
        Fastfetch.schedule();
    }
    function syncSystemTheme(force) {
        SystemTheme.sync(force);
    }

    // ── Persistence ───────────────────────────────────────────────────────
    function save() {
        const payload = JSON.stringify({
            theme: root.currentTheme,
            shape: root.shapeStyle
        });
        saveCmd.command = ["sh", "-c", Store.saveCommand(root.themePath, payload)];
        saveCmd.run();
        snapshotTimer.restart();
    }

    function load() {
        loadCmd.run();
    }

    Cmd {
        id: loadCmd
        command: ["bash", "-c", Store.loadCommand(root.themePath, root.legacyThemePath)]
        autorun: false
        onLine: function (line) {
            const data = Store.parse(line);
            if (!data)
                return;
            if (data.theme)
                root.currentTheme = data.theme;
            if (data.shape !== undefined)
                root.shapeStyle = data.shape;
            root._restoring = true;
            root.apply();
            root._restoring = false;
            snapshotTimer.restart();
        }
        onDone: root._themeLoaded = true
    }

    Cmd {
        id: saveCmd
        command: []
        autorun: false
    }

    // ── User themes: ~/.config/pill/themes/*.json ──────────────────────
    Cmd {
        id: userThemesCmd
        command: ["bash", "-c", "mkdir -p \"$HOME/.config/pill\"\n" + "if [ ! -d \"$HOME/.config/pill/themes\" ] && [ -d \"$HOME/.config/bubbles/themes\" ]; then " + "mv \"$HOME/.config/bubbles/themes\" \"$HOME/.config/pill/themes\"; fi\n" + "for f in \"$HOME\"/.config/pill/themes/*.json; do [ -f \"$f\" ] && jq -c . \"$f\" 2>/dev/null; done"]
        autorun: false
        onLine: function (line) {
            try {
                var t = Themes.validUserTheme(JSON.parse(line));
                if (t)
                    root.userThemes = root.userThemes.concat([t]);
                else
                    console.warn("Theme: ignoring invalid user theme:", line);
            } catch (e) {
                console.warn("Theme: failed to parse user theme:", e);
            }
        }
    }

    function reloadUserThemes() {
        root.userThemes = [];
        userThemesCmd.run();
    }

    // ── Greeter palette snapshot (PRD §6.5) ───────────────────────────────
    Timer {
        id: snapshotTimer
        interval: 800
        onTriggered: root.snapshot()
    }

    // Lock/sign-in pattern and wallpaper settings are part of the snapshot;
    // refresh it when they change so `pill greeter` pushes current values
    // without a theme apply.
    Connections {
        target: Config
        function onLockPatternChanged() {
            snapshotTimer.restart();
        }
        function onLockPatternStyleChanged() {
            snapshotTimer.restart();
        }
        function onLockPatternDensityChanged() {
            snapshotTimer.restart();
        }
        function onLockWallpaperChanged() {
            snapshotTimer.restart();
        }
        function onPatternStyleChanged() {
            snapshotTimer.restart();
        }
        function onPatternDensityChanged() {
            snapshotTimer.restart();
        }
    }

    function snapshot() {
        const payload = {
            background: Themes.hex(root.background),
            surface: Themes.hex(root.surface),
            accent: Themes.hex(root.accent),
            text: Themes.hex(root.text),
            subtext: Themes.hex(root.subtext),
            danger: Themes.hex(root.danger),
            border: Themes.hex(root.border),
            // Identity/typography, so the greeter matches the lock, not just
            // its colours: eyes on/off + expression, clock format, font.
            eyesEnabled: Config.eyesEnabled,
            eyeVariant: Config.eyeVariant,
            clockFormat: Config.clockFormat,
            fontFamily: Config.fontFamily,
            fontScale: Config.fontScale,
            // Lock/sign-in background: greeter mirrors the lock settings,
            // including their own pattern override.
            lockWallpaper: Config.lockWallpaper,
            lockPattern: Config.lockPattern,
            patternStyle: Config.effectiveLockPatternStyle,
            patternDensity: Config.effectiveLockPatternDensity
        };
        // A QML component, not JSON: the greeter can't XHR local files, but it
        // can load this from /etc/xdg/pill/GreeterPalette.qml. The timestamp
        // keeps the file a different size on every write, so Qt's QML disk
        // cache can never serve a stale palette. Versioned import: the X11
        // greeter engine is Qt 5.15, where versionless imports are fatal and
        // the palette silently falls back to the embedded one.
        const qml = "// Generated by Pill on theme apply. Do not edit.\n" + "// stamp: " + Date.now() + "\n" + "import QtQuick 2.15\n\n" + "QtObject {\n" + "    property var palette: " + JSON.stringify(payload) + "\n" + "}\n";
        snapshotCmd.command = ["sh", "-c", Store.saveCommand(root.cacheDir + "/GreeterPalette.qml", qml)];
        snapshotCmd.run();
    }

    Cmd {
        id: snapshotCmd
        command: []
        autorun: false
    }

    Component.onCompleted: {
        root.load();
        root.userThemes = [];
        userThemesCmd.run();
    }
}
