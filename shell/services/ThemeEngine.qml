pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string schemePath: stateDir + "/pill/scheme.json"

    property bool loaded: false
    property var scheme: null

    // Material You colours exposed as QML colours.
    property color background
    property color surface
    property color surfaceContainer
    property color surfaceContainerLow
    property color surfaceContainerHigh
    property color surfaceContainerHighest
    property color surfaceBright
    property color surfaceDim
    property color onSurface
    property color onSurfaceVariant
    property color primary
    property color onPrimary
    property color primaryContainer
    property color tertiary
    property color error
    property color errorContainer
    property color outline
    property color outlineVariant
    property color sourceColor

    // Convenience palette matching the static theme shape.
    readonly property var palette: loaded ? {
        background: root.background,
        surface: root.surfaceContainerLow,
        surfaceHover: root.surfaceContainer,
        highlight: root.surfaceContainerHigh,
        accent: root.primary,
        accentAlt: root.tertiary,
        text: root.onSurface,
        subtext: root.onSurfaceVariant,
        danger: root.error,
        dangerBg: root.errorContainer,
        dangerHover: root.error,
        border: root.outline
    } : null

    Process {
        id: loadProc
        command: ["jq", "-c", ".", root.schemePath]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    root.scheme = JSON.parse(line);
                    root.applyScheme();
                    root.loaded = true;
                } catch (e) {
                    console.warn("ThemeEngine: failed to parse scheme:", e);
                    root.loaded = false;
                }
            }
        }
    }

    function load() {
        loadProc.running = true;
    }

    function applyScheme() {
        const c = root.scheme.colors;
        const get = function(k) {
            return (c && c[k] && c[k].default && c[k].default.color) ? c[k].default.color : "#000000";
        };
        root.background = get("background");
        root.surface = get("surface");
        root.surfaceContainer = get("surface_container");
        root.surfaceContainerLow = get("surface_container_low");
        root.surfaceContainerHigh = get("surface_container_high");
        root.surfaceContainerHighest = get("surface_container_highest");
        root.surfaceBright = get("surface_bright");
        root.surfaceDim = get("surface_dim");
        root.onSurface = get("on_surface");
        root.onSurfaceVariant = get("on_surface_variant");
        root.primary = get("primary");
        root.onPrimary = get("on_primary");
        root.primaryContainer = get("primary_container");
        root.tertiary = get("tertiary");
        root.error = get("error");
        root.errorContainer = get("error_container");
        root.outline = get("outline");
        root.outlineVariant = get("outline_variant");
        root.sourceColor = get("source_color");
    }

    Component.onCompleted: root.load()
}
