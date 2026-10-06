import QtQuick

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [
        {
            label: "Refresh",
            icon: "󰑓",
            onTrigger: function () {
                Network.refreshProfiles();
            }
        }
    ]

    readonly property bool available: Integrations.has("nmcli")

    function refresh() {
        if (available)
            Network.refreshProfiles();
    }

    Repeater {
        model: Network.profiles

        SettingRow {
            id: profileRow
            required property var modelData
            icon: modelData.type === "vpn" || modelData.type === "wireguard" || modelData.type === "tun" ? "󰖂" : "󰈀"
            title: modelData.name
            subtitle: (modelData.type === "802-3-ethernet" ? "Wired" : modelData.type) + (modelData.device !== "" ? " • " + modelData.device : "") + (modelData.active ? " • Connected" : "")

            SettingAction {
                visible: !profileRow.modelData.active
                label: "Connect"
                accent: true
                onClicked: Network.setProfileUp(profileRow.modelData.name)
            }
            SettingAction {
                visible: profileRow.modelData.active
                label: "Disconnect"
                onClicked: Network.setProfileDown(profileRow.modelData.name)
            }
        }
    }

    SettingNote {
        visible: Network.profiles.length === 0
        text: root.available ? "No wired or VPN profiles configured (nmcli shows none)." : "nmcli not found — network profiles stay unmanaged here."
    }
}
