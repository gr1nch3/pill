import QtQuick
import "../../components"

import "../../services"
import "../controls"

SettingsPage {
    id: root

    SettingSection { icon: "󱁤"; label: "SYSTEM THEME" }

    SettingRow {
        icon: "󰏘"
        title: "Sync GTK & Qt"
        subtitle: "Write GTK 3/4 colours, the Qt6ct scheme and the dark/light hint on every theme change"
        SettingToggle {
            value: Config.syncSystemTheme
            onValueEdited: function(v) {
                Config.set("syncSystemTheme", v)
                ThemeController.scheduleSystemTheme()
                if (v) ThemeController.syncSystemTheme(true)
            }
        }
    }

    SettingRow {
        icon: "󰒓"
        title: "Sync Status"
        subtitle: !Config.syncSystemTheme
            ? "Disabled"
            : SystemTheme.syncing
                ? "Syncing..."
                : SystemTheme.everSynced
                    ? (SystemTheme.lastOk ? "GTK 3/4, Qt6ct and color-scheme up to date" : "Failed: " + SystemTheme.lastError)
                    : "Waiting for the first sync"
        SettingAction {
            label: "Sync Now"
            onClicked: ThemeController.syncSystemTheme(true)
        }
    }

    Text {
        width: parent.width
        text: "Existing gtk.css files are backed up once to ~/.local/state/bubbles/backup/; Bubbles only manages its own marked block, so custom rules and imports stay. Running apps pick the colours up on next launch. Qt needs QT_QPA_PLATFORMTHEME=qt6ct; Qt5/Kvantum themes stay manual."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }

    SettingSection { icon: "󰏘"; label: "APP RETINTING" }

    SettingRow {
        icon: "󰏘"
        title: "Matugen Templates"
        subtitle: Wallpaper.templateCount + " template(s) in ~/.config/matugen/config.toml — re-run on every theme change"
        SettingAction {
            label: "Re-apply"
            onClicked: ThemeController.reapplyTemplates()
        }
    }

    Text {
        width: parent.width
        text: "Add templates by editing ~/.config/matugen/config.toml (kitty, btop, qutebrowser, …; see theming/README.md), then press Re-apply. Fixed themes publish a scheme synthesized from Bubbles' palette, so every template matches."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }

    SettingSection { icon: "󱁤"; label: "TOOLS" }

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

    Text {
        width: parent.width
        text: "Missing tools leave their features hidden or inert (capture, theming, audio, network). `bubbles doctor` prints the same list with versions from a terminal."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }
}
