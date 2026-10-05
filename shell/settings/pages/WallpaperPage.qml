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

    actions: [
        { label: "Change…", icon: "󰋩", accent: true, onTrigger: function() { IslandState.open("wallpaper") } },
        { label: "Open Folder", icon: "󰉋", onTrigger: function() { root.openPath(Config.wallpaperDir) } }
    ]

    SettingNote {
        text: "The palette follows the wallpaper only while the Dynamic theme is active; with a fixed theme, changing the wallpaper just renders it."
    }

    SettingRow {
        icon: "󰋩"
        title: "Current"
        subtitle: Wallpaper.committedWallpaper !== ""
            ? Wallpaper.committedWallpaper.split("/").pop()
            : "None set"
        keywords: "change pick set background image"
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

    Process { id: openProc; command: []; running: false }
}
