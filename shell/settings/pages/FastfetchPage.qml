import QtQuick
import "../../components"

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [
        { label: "Apply Now", icon: "󰒓", accent: true, onTrigger: function() { Fastfetch.sync(true) } }
    ]

    SettingRow {
        icon: "󰄨"
        title: "Theme fastfetch"
        subtitle: "Write ~/.config/fastfetch/config.jsonc from the Bubbles palette on every theme change"
        SettingToggle {
            value: Config.fastfetchEnabled
            onValueEdited: function(v) {
                Config.set("fastfetchEnabled", v)
                if (v) Fastfetch.sync(true)
            }
        }
    }

    SettingRow {
        icon: "󰋩"
        title: "Logo"
        subtitle: "auto, none, a builtin name (arch, cachyos, …), small:<name>, or a file path"
        SettingEdit {
            value: Config.fastfetchLogo
            placeholder: "auto"
            onAccepted: function(text) {
                Config.set("fastfetchLogo", text)
                Fastfetch.sync(true)
            }
        }
    }

    SettingRow {
        icon: "󰈙"
        title: "Modules"
        subtitle: "Comma-separated fastfetch modules; empty keeps the default set"
        SettingEdit {
            value: Config.fastfetchModules
            placeholder: "title, os, host, kernel, …"
            onAccepted: function(text) {
                Config.set("fastfetchModules", text)
                Fastfetch.sync(true)
            }
        }
    }

    SettingRow {
        icon: "󰒓"
        title: "Status"
        subtitle: !Config.fastfetchEnabled
            ? "Disabled"
            : !Integrations.has("fastfetch")
                ? "fastfetch is not installed"
                : Fastfetch.syncing
                    ? "Writing..."
                    : Fastfetch.everSynced
                        ? (Fastfetch.lastOk ? "config.jsonc matches the current palette" : "Failed: " + Fastfetch.lastError)
                        : "Waiting for the first write"
        SettingAction {
            label: "Apply Now"
            onClicked: Fastfetch.sync(true)
        }
    }

    SettingNote {
        text: "A pre-existing config is backed up once to ~/.local/state/bubbles/backup/fastfetch-config.jsonc. Keys, title and output come from the palette; the logo and module list are yours to pick above. Run `fastfetch` in any terminal to see it."
    }
}
