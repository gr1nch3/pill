import QtQuick

import "../../services"
import "../../components"
import "../controls"

SettingsPage {
    id: root

    SettingSection { icon: "󰏘"; label: "THEME" }

    Text {
        width: parent.width
        text: "Dynamic builds a palette from the current wallpaper. Fixed themes ignore the wallpaper."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
        bottomPadding: 6
    }

    ThemeSelector { width: parent.width }

    SettingSection { icon: "󰉋"; label: "USER THEMES" }

    SettingRow {
        icon: "󰉋"
        title: "Custom Themes"
        subtitle: Theme.userThemes.length + " loaded from ~/.config/bubbles/themes/*.json"
        SettingAction {
            label: "Reload"
            onClicked: Theme.reloadUserThemes()
        }
    }

    Text {
        width: parent.width
        text: "Drop a JSON file with the built-in keys (name, source, background, surface, surfaceHover, highlight, accent, accentAlt, text, subtext, danger, dangerBg, dangerHover, border). A user theme with the same name replaces a built-in; `label` and `mode` are optional."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }
}
