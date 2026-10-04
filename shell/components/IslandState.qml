pragma Singleton
import QtQuick

import "../services"

QtObject {
    id: root

    // The currently active island view.
    readonly property bool isHorizontal: true
    property string state: "idle"

    // Sub-type for DeviceSelectState (wifi/bluetooth/audio/mic).
    property string deviceSelectType: ""

    // Target page for the next settings open ("wifi", "theme", …); set by IPC,
    // consumed (and cleared) by SettingsWindow.
    property string settingsPage: ""

    // True when the user is hovering the idle pill.
    property bool pillHovered: false

    // True when the user has explicitly expanded the idle pill.
    property bool pillExpanded: false

    // Convenience: the idle pill should show its expanded content.
    readonly property bool idleExpanded: (pillHovered || pillExpanded) && state === "idle"

    // True whenever the island is showing anything other than the idle bar.
    readonly property bool active: state !== "idle" || pillExpanded

    // False while the bar is auto-hidden — idle animations and polling pause.
    property bool shellActive: true

    // States whose active pane suppresses the volume/brightness OSD.
    readonly property var osdOwners: ({
        volume: ["controlcenter", "audiodevice", "connectivity", "settings"],
        brightness: ["controlcenter", "settings"]
    })

    // Workspace-change OSD dwell time.
    readonly property int navDismissMs: 1200

    function closeToIdle() {
        state = "idle"
        pillExpanded = false
        pillHovered = false
    }

    function open(nextState) {
        state = nextState
        pillExpanded = false
    }
}
