pragma Singleton
// Read-only palette facade. Data + pipeline live in services/ThemeController;
// this keeps the existing Theme.* call sites working and adds nothing else.
import QtQuick

import "../services"

Item {
    id: root

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

    readonly property var availableVariants: ThemeController.availableVariants
    readonly property var themes: ThemeController.themes
    readonly property var userThemes: ThemeController.userThemes
    readonly property string currentTheme: ThemeController.currentTheme
    readonly property string themeMode: ThemeController.themeMode
    readonly property string themeVariant: ThemeController.themeVariant
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
    readonly property color border: ThemeController.border
    readonly property var shape: ThemeController.shape
    readonly property var motion: ThemeController.motion
    readonly property var eyeMoods: ThemeController.eyeMoods

    function themeByName(name) { return ThemeController.themeByName(name) }
    function applyTheme() { ThemeController.apply() }
    function setTheme(name) { ThemeController.setTheme(name) }
    function setMode(mode) { ThemeController.setMode(mode) }
    function setVariant(variant) { ThemeController.setVariant(variant) }
    function setShape(style) { ThemeController.setShape(style) }
    function shapeInset(w, h) { return ThemeController.shapeInset(w, h) }
    function nextTheme() { ThemeController.nextTheme() }
    function save() { ThemeController.save() }
    function load() { ThemeController.load() }
    function reloadUserThemes() { ThemeController.reloadUserThemes() }
    function resolvedScheme() { return ThemeController.resolvedScheme() }
    function writeGreeterSnapshot() { ThemeController.snapshot() }
}
