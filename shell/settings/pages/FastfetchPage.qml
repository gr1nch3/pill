import QtQuick
import "../../components"

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [
        {
            label: "Apply Now",
            icon: "󰒓",
            accent: true,
            onTrigger: function () {
                Fastfetch.sync(true);
            }
        }
    ]

    property string customDraft: ""

    readonly property var logoOptions: [
        {
            value: "auto",
            label: "Auto (distro logo)"
        },
        {
            value: "bubbles",
            label: "Bubbles (three bubbles)"
        },
        {
            value: "none",
            label: "None"
        },
        {
            value: "arch",
            label: "Arch"
        },
        {
            value: "cachyos",
            label: "CachyOS"
        },
        {
            value: "endeavouros",
            label: "EndeavourOS"
        },
        {
            value: "fedora",
            label: "Fedora"
        },
        {
            value: "ubuntu",
            label: "Ubuntu"
        },
        {
            value: "debian",
            label: "Debian"
        },
        {
            value: "opensuse",
            label: "openSUSE"
        },
        {
            value: "nixos",
            label: "NixOS"
        },
        {
            value: "void",
            label: "Void"
        },
        {
            value: "gentoo",
            label: "Gentoo"
        },
        {
            value: "alpine",
            label: "Alpine"
        },
        {
            value: "__custom",
            label: "Custom…"
        }
    ]

    function pickLogo(value) {
        if (value === "__custom") {
            root.customDraft = Config.fastfetchLogo;
            customLogoDialog.open();
            return;
        }
        Config.set("fastfetchLogo", value);
        Fastfetch.sync(true);
    }

    function saveCustomLogo() {
        Config.set("fastfetchLogo", root.customDraft.trim());
        Fastfetch.sync(true);
        customLogoDialog.close();
    }

    SettingRow {
        icon: "󰄨"
        title: "Theme fastfetch"
        subtitle: "Write ~/.config/fastfetch/config.jsonc from the Bubbles palette on every theme change"
        SettingToggle {
            value: Config.fastfetchEnabled
            onValueEdited: function (v) {
                Config.set("fastfetchEnabled", v);
                if (v)
                    Fastfetch.sync(true);
            }
        }
    }

    SettingRow {
        icon: "󰋩"
        title: "Logo"
        subtitle: "The mark printed beside the fetch; Custom covers any builtin, small:<name> or file path"
        SettingSelect {
            width: 230
            options: root.logoOptions
            currentValue: Config.fastfetchLogo !== "" ? Config.fastfetchLogo : "auto"
            placeholder: "auto"
            onValueSelected: function (value) {
                root.pickLogo(value);
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
            onAccepted: function (text) {
                Config.set("fastfetchModules", text);
                Fastfetch.sync(true);
            }
        }
    }

    SettingRow {
        icon: "󰒓"
        title: "Status"
        subtitle: !Config.fastfetchEnabled ? "Disabled" : !Integrations.has("fastfetch") ? "fastfetch is not installed" : Fastfetch.syncing ? "Writing..." : Fastfetch.everSynced ? (Fastfetch.lastOk ? "config.jsonc matches the current palette" : "Failed: " + Fastfetch.lastError) : "Waiting for the first write"
        SettingAction {
            label: "Apply Now"
            onClicked: Fastfetch.sync(true)
        }
    }

    SettingNote {
        text: "A pre-existing config is backed up once to ~/.local/state/bubbles/backup/fastfetch-config.jsonc. Keys, title and output come from the palette; the logo and module list are yours to pick above. Run `fastfetch` in any terminal to see it."
    }

    SettingDialog {
        id: customLogoDialog
        title: "Custom logo"
        description: "A fastfetch builtin name, small:<name>, or a path to an image/text file."

        SettingEdit {
            id: customField
            width: parent.width
            textAlign: Text.AlignLeft
            live: true
            value: root.customDraft
            placeholder: "small:arch or /home/…/logo.png"
            onTextEdited: function (text) {
                root.customDraft = text;
            }
            onAccepted: root.saveCustomLogo()
        }

        Item {
            width: parent.width
            height: 30

            Row {
                anchors.right: parent.right
                spacing: 8

                SettingAction {
                    label: "Cancel"
                    onClicked: customLogoDialog.close()
                }
                SettingAction {
                    label: "Save"
                    accent: true
                    onClicked: root.saveCustomLogo()
                }
            }
        }

        onOpened: customField.focusInput()
    }
}
