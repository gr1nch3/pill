import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    function openPath(path) {
        openProc.command = ["xdg-open", path]
        openProc.running = true
    }

    SettingSection { icon: "󰋩"; label: "WALLPAPER" }

    SettingRow {
        icon: "󰋩"
        title: "Current"
        subtitle: Wallpaper.committedWallpaper !== ""
            ? Wallpaper.committedWallpaper.split("/").pop()
            : "None set"
        SettingAction {
            label: "Change"
            onClicked: IslandState.open("wallpaper")
        }
    }

    SettingRow {
        icon: "󰉋"
        title: "Library Folder"
        subtitle: Config.wallpaperDir
        SettingAction {
            label: "Open"
            onClicked: root.openPath(Config.wallpaperDir)
        }
    }

    Text {
        width: parent.width
        text: "The palette follows the wallpaper only while the Dynamic theme is active; with a fixed theme, changing the wallpaper just renders it."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }

    Process { id: openProc; command: []; running: false }
}
