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

    SettingSection { icon: "󰉋"; label: "FOLDERS" }

    SettingRow {
        icon: "󰸉"
        title: "Wallpapers"
        subtitle: Config.wallpaperDir
        SettingAction { label: "Open"; onClicked: root.openPath(Config.wallpaperDir) }
    }

    SettingRow {
        icon: "󰹑"
        title: "Screenshots"
        subtitle: Config.screenshotDir
        SettingAction { label: "Open"; onClicked: root.openPath(Config.screenshotDir) }
    }

    SettingRow {
        icon: "󰎁"
        title: "Recordings"
        subtitle: Config.recordingDir
        SettingAction { label: "Open"; onClicked: root.openPath(Config.recordingDir) }
    }

    SettingRow {
        icon: "󰓃"
        title: "Cava Config"
        subtitle: Config.cavaConfig
        SettingAction { label: "Open"; onClicked: root.openPath(Config.cavaConfig) }
    }

    SettingRow {
        icon: "󰒓"
        title: "Bubbles Config"
        subtitle: Config.configPath
        SettingAction { label: "Open"; onClicked: root.openPath(Config.configPath) }
    }

    Process { id: openProc; command: []; running: false }
}
