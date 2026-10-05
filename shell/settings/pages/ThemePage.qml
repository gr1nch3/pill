import QtQuick

import "../../services"
import "../../components"
import "../controls"

SettingsPage {
    id: root

    actions: [
        {
            label: "Reload Themes",
            icon: "󰑓",
            onTrigger: function () {
                Theme.reloadUserThemes();
            }
        }
    ]

    SettingNote {
        text: "Dynamic builds a palette from the current wallpaper via wallust (palette/backend in ~/.config/wallust/wallust.toml); fixed themes ignore it."
    }

    ThemeSelector {
        width: parent.width
    }

    SettingSection {
        icon: "󰉋"
        label: "USER THEMES"
    }

    SettingRow {
        icon: "󰉋"
        title: "Custom Themes"
        subtitle: Theme.userThemes.length + " loaded from ~/.config/bubbles/themes/*.json"
        SettingAction {
            label: "Reload"
            onClicked: Theme.reloadUserThemes()
        }
    }

    SettingNote {
        text: "Drop a JSON file with the built-in keys (name, source, background, surface, surfaceHover, highlight, accent, accentAlt, text, subtext, danger, dangerBg, dangerHover, border). A user theme with the same name replaces a built-in; `label` and `mode` are optional."
    }
}
