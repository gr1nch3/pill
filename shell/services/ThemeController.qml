pragma Singleton
// Owns theme selection, persistence, palette resolution and the apply
// pipeline: publish scheme -> reload palette -> re-run matugen templates ->
// sync GTK/Qt. Wallpaper renders, ThemeEngine stores the palette, SystemTheme
// writes system files; none of them know about each other.
import QtQuick
import Quickshell

import "../utils"
import "../utils/Themes.js" as Themes
import "../utils/shquote.js" as Sh

Item {
    id: root

    readonly property string _stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string themePath: _stateDir + "/bubbles/theme.json"
    readonly property string legacyThemePath: _stateDir + "/pill/theme.json"
    readonly property string matugenConfig: Quickshell.env("HOME") + "/.config/matugen/config.toml"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/bubbles"

    property string currentTheme: "dynamic"
    property string themeMode: Config.themeMode
    property string themeVariant: Config.themeVariant
    // "" = use the active theme's own shape style.
    property string shapeStyle: ""
    property var userThemes: []
    // True only during the startup load; apply() then keeps the on-disk
    // scheme instead of re-deriving it (the autostart wallpaper set does).
    property bool _restoring: false

    readonly property var availableVariants: Themes.availableVariants

    // ── Palette resolution ────────────────────────────────────────────────
    function _dynamicEntry() {
        var p = ThemeEngine.loaded && ThemeEngine.palette
            ? ThemeEngine.palette
            : Themes.dynamicFallback(root.themeMode)
        return {
            name: "dynamic", label: "Dynamic", source: "", mode: "",
            background: p.background, surface: p.surface, surfaceHover: p.surfaceHover,
            highlight: p.highlight, accent: p.accent, accentAlt: p.accentAlt,
            text: p.text, subtext: p.subtext, danger: p.danger, dangerBg: p.dangerBg,
            dangerHover: p.dangerHover, border: p.border,
            shape: Themes.defaultShape, motion: Themes.defaultMotion
        }
    }

    readonly property var themes: {
        var out = [root._dynamicEntry()].concat(Themes.builtins.map(Themes.withStyle))
        for (var i = 0; i < root.userThemes.length; i++) {
            var u = root.userThemes[i]
            var replaced = false
            for (var j = 0; j < out.length; j++) {
                if (out[j].name === u.name) { out[j] = u; replaced = true; break }
            }
            if (!replaced) out.push(u)
        }
        return out
    }

    function themeByName(name) {
        for (var i = 0; i < root.themes.length; i++)
            if (root.themes[i].name === name) return root.themes[i]
        return null
    }

    readonly property var _t: {
        if (root.currentTheme === "dynamic" && ThemeEngine.loaded && ThemeEngine.palette)
            return ThemeEngine.palette
        for (var i = 0; i < root.themes.length; i++)
            if (root.themes[i].name === root.currentTheme) return root.themes[i]
        return root.themes[0]
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
    readonly property color border: {
        if (root.currentTheme === "dynamic" && ThemeEngine.loaded && ThemeEngine.palette)
            return Qt.rgba(ThemeEngine.palette.border.r, ThemeEngine.palette.border.g,
                ThemeEngine.palette.border.b, 0.35)
        return root._t.border
    }

    // ── Shape + motion tokens (per-theme, defaulted) ──────────────────────
    readonly property var shape: {
        var base = root._t.shape || Themes.defaultShape
        if (root.shapeStyle === "") return base
        return {
            style: root.shapeStyle,
            slant: base.slant,
            radius: base.radius,
            border: base.border
        }
    }
    readonly property var motion: root._t.motion || Themes.defaultMotion

    // ── Eye identity palette (PRD §6.3) ─────────────────────────────────────
    readonly property var eyeMoods: ({
        idle:   { color: root._t.subtext, opacity: 0.55 },
        active: { color: root._t.accent, opacity: 1.0 },
        alert:  { color: "#f0a500", opacity: 1.0 },
        error:  { color: root._t.danger, opacity: 1.0 }
    })

    // ── Pipeline status ───────────────────────────────────────────────────
    property bool busy: false
    property bool lastOk: true
    property string lastError: ""

    function setTheme(name) {
        root.currentTheme = name
        root.save()
        root.apply()
    }

    function setMode(mode) {
        root.themeMode = mode
        root.save()
        root._afterPreferenceChange()
    }

    function setVariant(variant) {
        root.themeVariant = variant
        root.save()
        root._afterPreferenceChange()
    }

    function setShape(style) {
        root.shapeStyle = style
        root.save()
    }

    // Horizontal inset a polygon style needs so content fits the background.
    function shapeInset(w, h) {
        return Themes.shapeCut(root.shape.style, root.shape.slant, w, h)
    }

    function nextTheme() {
        var names = root.themes.map(t => t.name)
        var idx = names.indexOf(root.currentTheme)
        root.currentTheme = names[(idx + 1) % names.length]
        root.save()
        root.apply()
    }

    function _afterPreferenceChange() {
        if (root.currentTheme === "dynamic" && Wallpaper.committedWallpaper)
            Wallpaper.regenerate(root.themeMode, root.themeVariant)
        else if (root.currentTheme === "dynamic")
            root.reapplyTemplates()
        root.scheduleSystemTheme()
    }

    function apply() {
        if (root.currentTheme === "dynamic") {
            // Switching to dynamic re-derives the scheme from the current
            // wallpaper; restoring on startup reuses the scheme on disk.
            if (!root._restoring && Wallpaper.committedWallpaper)
                Wallpaper.regenerate(root.themeMode, root.themeVariant)
            else
                root.reapplyTemplates()
            root.scheduleSystemTheme()
            return
        }
        var t = root.themeByName(root.currentTheme)
        if (!t || !t.source) return
        root._publishScheme()
    }

    // Fixed themes: publish a scheme synthesized from the resolved palette so
    // every matugen template matches Bubbles exactly.
    function _publishScheme() {
        root.busy = true
        publishCmd.command = ["bash", "-c",
            "mkdir -p " + Sh.q(ThemeEngine.stateDir + "/bubbles") + " && printf '%s' " +
            Sh.q(JSON.stringify(root.resolvedScheme())) + " > " + Sh.q(ThemeEngine.schemePath)]
        publishCmd.run()
    }

    Cmd {
        id: publishCmd
        autorun: false
        onDone: {
            ThemeEngine.reload()
            root.reapplyTemplates()
        }
    }

    function reapplyTemplates() {
        if (!Integrations.has("matugen")) {
            root.scheduleSystemTheme()
            return
        }
        templatesCmd.command = ["bash", "-c",
            "matugen json " + Sh.q(ThemeEngine.schemePath) + " -c " + Sh.q(root.matugenConfig)]
        templatesCmd.run()
    }

    Cmd {
        id: templatesCmd
        autorun: false
        onDone: function(code) {
            root.busy = false
            root.lastOk = code === 0
            root.lastError = root.lastOk ? "" : ("matugen exit " + code)
            root.scheduleSystemTheme()
            snapshotTimer.restart()
        }
    }

    // ── Wallpaper hook ────────────────────────────────────────────────────
    function setWallpaper(path) {
        Wallpaper.set(path, root.themeMode, root.themeVariant, root.currentTheme === "dynamic")
    }

    Connections {
        target: Wallpaper
        function onApplied(path) {
            // Only the dynamic theme follows the wallpaper; under a fixed
            // theme the render happened but the palette stays put.
            if (root.currentTheme !== "dynamic") return
            ThemeEngine.reload()
            root.reapplyTemplates()
        }
    }

    // ── Palette-derived side effects (only this module talks to them) ─────
    // Fastfetch rides the same schedule as the system theme: every apply /
    // preference change rewrites its config from the resolved palette.
    function scheduleSystemTheme() { SystemTheme.schedule(); Fastfetch.schedule() }
    function syncSystemTheme(force) { SystemTheme.sync(force) }

    // ── Persistence ───────────────────────────────────────────────────────
    function save() {
        const payload = JSON.stringify({
            theme: root.currentTheme,
            mode: root.themeMode,
            variant: root.themeVariant,
            shape: root.shapeStyle
        })
        saveCmd.command = ["sh", "-c", Store.saveCommand(root.themePath, payload)]
        saveCmd.run()
        snapshotTimer.restart()
    }

    function load() {
        loadCmd.run()
    }

    Cmd {
        id: loadCmd
        command: ["bash", "-c", Store.loadCommand(root.themePath, root.legacyThemePath)]
        autorun: false
        onLine: function(line) {
            const data = Store.parse(line)
            if (!data) return
            if (data.theme) root.currentTheme = data.theme
            if (data.mode) root.themeMode = data.mode
            if (data.variant) root.themeVariant = data.variant
            if (data.shape !== undefined) root.shapeStyle = data.shape
            root._restoring = true
            root.apply()
            root._restoring = false
            snapshotTimer.restart()
        }
    }

    Cmd {
        id: saveCmd
        command: []
        autorun: false
    }

    // ── User themes: ~/.config/bubbles/themes/*.json ──────────────────────
    Cmd {
        id: userThemesCmd
        command: ["bash", "-c",
            "mkdir -p \"$HOME/.config/bubbles\"\n" +
            "if [ ! -d \"$HOME/.config/bubbles/themes\" ] && [ -d \"$HOME/.config/pill/themes\" ]; then " +
                "mv \"$HOME/.config/pill/themes\" \"$HOME/.config/bubbles/themes\"; fi\n" +
            "for f in \"$HOME\"/.config/bubbles/themes/*.json; do [ -f \"$f\" ] && jq -c . \"$f\" 2>/dev/null; done"]
        autorun: false
        onLine: function(line) {
            try {
                var t = Themes.validUserTheme(JSON.parse(line))
                if (t) root.userThemes = root.userThemes.concat([t])
                else console.warn("Theme: ignoring invalid user theme:", line)
            } catch (e) {
                console.warn("Theme: failed to parse user theme:", e)
            }
        }
    }

    function reloadUserThemes() {
        root.userThemes = []
        userThemesCmd.run()
    }

    // Material scheme synthesized from the *resolved* palette.
    function resolvedScheme() {
        var wrap = function(h) { return { default: { color: h } } }
        var bg = Themes.hex(root.background), surf = Themes.hex(root.surface), hover = Themes.hex(root.surfaceHover)
        var hl = Themes.hex(root.highlight), acc = Themes.hex(root.accent), alt = Themes.hex(root.accentAlt)
        var txt = Themes.hex(root.text), sub = Themes.hex(root.subtext), dang = Themes.hex(root.danger)
        var dangBg = Themes.hex(root.dangerBg), bd = Themes.hex(root._t.border)
        var onAcc = Themes.contrast(root.accent), onAlt = Themes.contrast(root.accentAlt), onDang = Themes.contrast(root.danger)
        var dark = (0.299 * root.background.r + 0.587 * root.background.g + 0.114 * root.background.b) < 0.5
        return {
            source_color: acc,
            mode: dark ? "dark" : "light",
            colors: {
                background: wrap(bg), on_background: wrap(txt),
                surface: wrap(surf), on_surface: wrap(txt),
                surface_variant: wrap(hover), on_surface_variant: wrap(sub),
                surface_container_lowest: wrap(bg), surface_container_low: wrap(surf),
                surface_container: wrap(hover), surface_container_high: wrap(hl),
                surface_container_highest: wrap(hl), surface_bright: wrap(hl), surface_dim: wrap(bg),
                primary: wrap(acc), on_primary: wrap(onAcc),
                primary_container: wrap(hl), on_primary_container: wrap(txt),
                secondary: wrap(alt), on_secondary: wrap(onAlt),
                secondary_container: wrap(surf), on_secondary_container: wrap(txt),
                tertiary: wrap(alt), on_tertiary: wrap(onAlt),
                tertiary_container: wrap(surf), on_tertiary_container: wrap(txt),
                error: wrap(dang), on_error: wrap(onDang),
                error_container: wrap(dangBg), on_error_container: wrap(txt),
                outline: wrap(bd), outline_variant: wrap(hover),
                inverse_surface: wrap(txt), inverse_on_surface: wrap(bg), inverse_primary: wrap(alt),
                shadow: wrap("#000000"), scrim: wrap("#000000"), surface_tint: wrap(acc)
            }
        }
    }

    // ── Greeter palette snapshot (PRD §6.5) ───────────────────────────────
    Timer {
        id: snapshotTimer
        interval: 800
        onTriggered: root.snapshot()
    }

    // Lock/sign-in pattern and wallpaper settings are part of the snapshot;
    // refresh it when they change so `bubbles greeter` pushes current values
    // without a theme apply.
    Connections {
        target: Config
        function onLockPatternChanged() { snapshotTimer.restart() }
        function onLockPatternStyleChanged() { snapshotTimer.restart() }
        function onLockPatternDensityChanged() { snapshotTimer.restart() }
        function onLockWallpaperChanged() { snapshotTimer.restart() }
        function onPatternStyleChanged() { snapshotTimer.restart() }
        function onPatternDensityChanged() { snapshotTimer.restart() }
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
        }
        // A QML component, not JSON: the greeter can't XHR local files, but it
        // can load this from /etc/xdg/bubbles/GreeterPalette.qml. The timestamp
        // keeps the file a different size on every write, so Qt's QML disk
        // cache can never serve a stale palette. Versioned import: the X11
        // greeter engine is Qt 5.15, where versionless imports are fatal and
        // the palette silently falls back to the embedded one.
        const qml = "// Generated by Bubbles on theme apply. Do not edit.\n"
            + "// stamp: " + Date.now() + "\n"
            + "import QtQuick 2.15\n\n"
            + "QtObject {\n"
            + "    property var palette: " + JSON.stringify(payload) + "\n"
            + "}\n"
        snapshotCmd.command = ["sh", "-c", Store.saveCommand(root.cacheDir + "/GreeterPalette.qml", qml)]
        snapshotCmd.run()
    }

    Cmd {
        id: snapshotCmd
        command: []
        autorun: false
    }

    Component.onCompleted: {
        root.load()
        root.userThemes = []
        userThemesCmd.run()
    }
}
