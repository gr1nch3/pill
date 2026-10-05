import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [
        { label: "Open Config", icon: "󰒓",
          onTrigger: function() { root.openPath(Config.configPath) } }
    ]

    readonly property var folders: [
        { icon: "󰸉", title: "Wallpapers",  path: Config.wallpaperDir },
        { icon: "󰹑", title: "Screenshots", path: Config.screenshotDir },
        { icon: "󰎁", title: "Recordings",  path: Config.recordingDir },
        { icon: "󰓃", title: "Cava Config", path: Config.cavaConfig },
        { icon: "󰒓", title: "Bubbles Config", path: Config.configPath }
    ]

    function openPath(path) {
        openProc.command = ["xdg-open", path]
        openProc.running = true
    }

    SettingSection {
        icon: "󰉋"; label: "FOLDERS"
        description: "The paths the shell reads and writes."
    }

    Grid {
        width: parent.width
        columns: 3
        spacing: 8

        Repeater {
            model: root.folders

            delegate: SettingTile {
                id: folderTile
                required property var modelData
                width: (parent.width - 16) / 3
                icon: folderTile.modelData.icon
                title: folderTile.modelData.title
                hint: folderTile.modelData.path.split("/").slice(-2).join("/")
                onClicked: root.openPath(folderTile.modelData.path)
            }
        }
    }

    Process { id: openProc; command: []; running: false }
}
