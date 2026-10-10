pragma Singleton
// Read-only palette facade. Data + pipeline live in services/ThemeController;
// this keeps the existing Theme.* call sites working and adds nothing else.
import QtQuick

import "../services"

Item {
    id: root

    // variable key on Qt.application: its `font` property isn't in qmllint's
    // QtQuick type info, and it's real at runtime.
    readonly property string _systemFont: {
        var app = Qt.application;
        var fontKey = "font";
        return app[fontKey].family;
    }

    readonly property FontTokens font: FontTokens {
        family: Config.fontFamily !== "" ? Config.fontFamily : root._systemFont
        mono: Config.iconFontFamily
        size: FontSize {
            scale: Config.fontScale
        }
    }

    readonly property var themes: ThemeController.themes
    readonly property var userThemes: ThemeController.userThemes
    readonly property string currentTheme: ThemeController.currentTheme
    readonly property string shapeStyle: ThemeController.shapeStyle

    readonly property color background: ThemeController.background
    readonly property color surface: ThemeController.surface
    readonly property color surfaceHover: ThemeController.surfaceHover
    readonly property color highlight: ThemeController.highlight
    readonly property color accent: ThemeController.accent
    readonly property color accentAlt: ThemeController.accentAlt
    readonly property color text: ThemeController.text
    readonly property color subtext: ThemeController.subtext
    readonly property color danger: ThemeController.danger
    readonly property color dangerBg: ThemeController.dangerBg
    readonly property color dangerHover: ThemeController.dangerHover
    readonly property color warning: ThemeController.warning
    readonly property color success: ThemeController.success
    readonly property color border: ThemeController.border
    readonly property var shape: ThemeController.shape
    readonly property var motion: ThemeController.motion
    readonly property var eyeMoods: ThemeController.eyeMoods

    // Pattern pitch for PatternBackground consumers (px between motifs).
    readonly property int patternSpacing: Config.patternDensity === "dense" ? 13 : (Config.patternDensity === "sparse" ? 26 : 18)

    function themeByName(name) {
        return ThemeController.themeByName(name);
    }
    // Ink for a status tone: muted | danger | warning | success.
    function statusColor(tone) {
        if (tone === "danger")
            return danger;
        if (tone === "warning")
            return warning;
        if (tone === "success")
            return success;
        return subtext;
    }
    function applyTheme() {
        ThemeController.apply();
    }
    function setTheme(name) {
        ThemeController.setTheme(name);
    }
    function setShape(style) {
        ThemeController.setShape(style);
    }
    function shapeInset(w, h) {
        return ThemeController.shapeInset(w, h);
    }
    function nextTheme() {
        ThemeController.nextTheme();
    }
    function save() {
        ThemeController.save();
    }
    function load() {
        ThemeController.load();
    }
    function reloadUserThemes() {
        ThemeController.reloadUserThemes();
    }
    function writeGreeterSnapshot() {
        ThemeController.snapshot();
    }
}
