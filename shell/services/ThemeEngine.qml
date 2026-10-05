pragma Singleton
// Palette store: reads the wallust colourscheme and exposes one palette
// object. Selection and the apply pipeline live in ThemeController; views
// read Theme.
import QtQuick
import Quickshell

import "../utils"
import "../utils/Themes.js" as Themes

Item {
    id: root

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string schemePath: stateDir + "/bubbles/scheme.json"
    readonly property string legacySchemePath: stateDir + "/pill/scheme.json"

    property bool loaded: false
    // final: QQuickItem already has a `palette`; this one carries the
    // resolved theme palette and must not shadow-trip qmllint's override check.
    final property var palette: null

    Cmd {
        id: loadCmd
        command: ["bash", "-c", Store.loadCommand(root.schemePath, root.legacySchemePath)]
        autorun: false
        onLine: function (line) {
            var data = Store.parse(line);
            if (data) {
                root.palette = Themes.paletteFromWallust(data);
                root.loaded = true;
            } else {
                root.loaded = false;
            }
        }
    }

    function reload() {
        loadCmd.run();
    }

    Component.onCompleted: root.reload()
}
