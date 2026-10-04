pragma Singleton
// Palette store: reads the matugen scheme and exposes one palette object.
// Selection and the apply pipeline live in ThemeController; views read Theme.
import QtQuick
import Quickshell

import "../utils"

Item {
    id: root

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string schemePath: stateDir + "/bubbles/scheme.json"
    readonly property string legacySchemePath: stateDir + "/pill/scheme.json"

    property bool loaded: false
    property var palette: null

    Cmd {
        id: loadCmd
        command: ["bash", "-c", Store.loadCommand(root.schemePath, root.legacySchemePath)]
        autorun: false
        onLine: function(line) {
            var data = Store.parse(line)
            if (data) {
                root.palette = root._paletteOf(data)
                root.loaded = true
            } else {
                root.loaded = false
            }
        }
    }

    function reload() {
        loadCmd.run()
    }

    function _paletteOf(scheme) {
        const c = scheme.colors
        const get = function(k) {
            return (c && c[k] && c[k].default && c[k].default.color) ? c[k].default.color : "#000000"
        }
        return {
            background: get("background"),
            surface: get("surface_container_low"),
            surfaceHover: get("surface_container"),
            highlight: get("surface_container_high"),
            accent: get("primary"),
            accentAlt: get("tertiary"),
            text: get("on_surface"),
            subtext: get("on_surface_variant"),
            danger: get("error"),
            dangerBg: get("error_container"),
            dangerHover: get("error"),
            border: get("outline")
        }
    }

    Component.onCompleted: root.reload()
}
