import QtQuick
import "../../components"

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [
        {
            label: "Sync GTK & Qt",
            icon: "󰒓",
            accent: true,
            onTrigger: function () {
                ThemeController.syncSystemTheme(true);
            }
        },
        {
            label: "Re-apply Templates",
            icon: "󰑓",
            onTrigger: function () {
                ThemeController.reapplyTemplates();
            }
        }
    ]

    SettingSection {
        icon: "󱁤"
        label: "SYSTEM THEME"
        description: "Write GTK 3/4 colours, the Qt6ct scheme and the dark/light hint on every theme change. Pill only manages its own marked block, so custom gtk.css rules survive; existing files are backed up once."
    }

    SettingRow {
        icon: "󰏘"
        title: "Sync GTK & Qt"
        subtitle: "Keep GTK colours and the dark/light hint in step with the shell"
        keywords: "adwaita qt6ct color color-scheme dark light"
        SettingToggle {
            value: Config.syncSystemTheme
            onValueEdited: function (v) {
                Config.set("syncSystemTheme", v);
                ThemeController.scheduleSystemTheme();
                if (v)
                    ThemeController.syncSystemTheme(true);
            }
        }
    }

    SettingRow {
        icon: "󰒓"
        title: "Sync Status"
        subtitle: !Config.syncSystemTheme ? "Disabled" : SystemTheme.syncing ? "Syncing..." : SystemTheme.everSynced ? (SystemTheme.lastOk ? "GTK 3/4, Qt6ct and color-scheme up to date" : "Failed: " + SystemTheme.lastError) : "Waiting for the first sync"
        SettingAction {
            label: "Sync Now"
            onClicked: ThemeController.syncSystemTheme(true)
        }
    }

    SettingNote {
        text: "Running apps pick the colours up on next launch. Qt needs QT_QPA_PLATFORMTHEME=qt6ct; Qt5/Kvantum themes stay manual."
    }

    SettingSection {
        icon: "󰏘"
        label: "APP RETINTING"
        description: "Templates live in ~/.config/wallust/wallust.toml (kitty, btop, qutebrowser, …) and re-run on every theme change — fixed themes included, from a scheme synthesized from Pill' palette."
    }

    SettingRow {
        icon: "󰏘"
        title: "wallust Templates"
        subtitle: Wallpaper.templateCount + " template(s) configured in ~/.config/wallust/wallust.toml"
        SettingAction {
            label: "Re-apply"
            onClicked: ThemeController.reapplyTemplates()
        }
    }

    SettingNote {
        text: "Add templates by editing ~/.config/wallust/wallust.toml (kitty, btop, qutebrowser, …; see theming/README.md), then press Re-apply."
    }

    SettingSection {
        icon: "󱁤"
        label: "TOOLS"
        description: "Missing tools leave their features hidden or inert (capture, theming, audio, network). `pill doctor` prints the same list with versions from a terminal."
    }

    Flow {
        width: parent.width
        spacing: 6

        Repeater {
            model: Integrations.known

            delegate: Rectangle {
                required property string modelData
                width: toolName.implicitWidth + 18
                height: 26
                radius: Theme.shape.radius.control
                color: Integrations.has(modelData) ? Theme.background : Theme.dangerBg
                border.width: Theme.shape.border.width
                border.color: Integrations.has(modelData) ? Theme.border : Theme.danger

                Text {
                    id: toolName
                    anchors.centerIn: parent
                    text: modelData
                    color: Integrations.has(modelData) ? Theme.text : Theme.danger
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                }
            }
        }
    }
}
