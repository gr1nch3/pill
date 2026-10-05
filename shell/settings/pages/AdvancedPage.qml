import QtQuick
import "../../components"

import "../../services"
import "../../utils"
import "../controls"

SettingsPage {
    id: root

    actions: [
        {
            label: "Open Config",
            icon: "󰒓",
            onTrigger: function () {
                Opener.path(Config.configPath);
            }
        }
    ]

    readonly property var folders: [
        {
            icon: "󰸉",
            title: "Wallpapers",
            path: Config.wallpaperDir
        },
        {
            icon: "󰹑",
            title: "Screenshots",
            path: Config.screenshotDir
        },
        {
            icon: "󰎁",
            title: "Recordings",
            path: Config.recordingDir
        },
        {
            icon: "󰓃",
            title: "Cava Config",
            path: Config.cavaConfig
        },
        {
            icon: "󰒓",
            title: "Bubbles Config",
            path: Config.configPath
        }
    ]

    SettingSection {
        icon: "󰉋"
        label: "FOLDERS"
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
                onClicked: Opener.path(folderTile.modelData.path)
            }
        }
    }
}
