pragma Singleton
// Hyprland workspace state for the navigation OSD. Inert off Hyprland.
import QtQuick
import Quickshell
import Quickshell.Hyprland as QsHypr

Item {
    id: root

    property int activeId: 1
    property var displayIds: [1, 2, 3, 4, 5]
    property var occupiedMap: ({})

    function refresh() {
        var ws = QsHypr.Hyprland.focusedWorkspace;
        root.activeId = ws ? ws.id : 1;

        var map = {};
        var ids = [1, 2, 3, 4, 5];
        var vals = QsHypr.Hyprland.workspaces ? QsHypr.Hyprland.workspaces.values : null;
        if (vals) {
            var len = vals.length;
            for (var i = 0; i < len; i++) {
                var w = vals[i];
                var winCount = w.lastIpcObject ? w.lastIpcObject.windows || 0 : 0;
                map[w.id] = winCount > 0;
                if (w.id > 5 && (winCount > 0 || w.id === root.activeId)) {
                    if (ids.indexOf(w.id) === -1)
                        ids.push(w.id);
                }
            }
        }
        ids.sort(function (a, b) {
            return a - b;
        });
        root.displayIds = ids;
        root.occupiedMap = map;
    }

    Connections {
        target: QsHypr.Hyprland
        function onFocusedWorkspaceChanged() {
            root.refresh();
        }
    }

    Component.onCompleted: root.refresh()
}
