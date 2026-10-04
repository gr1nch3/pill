import QtQuick

import "../../services"
import "../../components"
import "../controls"

SettingsPage {
    id: root

    readonly property bool available: Integrations.has("nmcli")

    function refresh() {
        if (available) Network.refreshProfiles()
    }

    SettingSection { icon: "󰈀"; label: "ETHERNET & VPN" }

    Repeater {
        model: Network.profiles

        SettingRow {
            id: profileRow
            required property var modelData
            icon: modelData.type === "vpn" || modelData.type === "wireguard" || modelData.type === "tun" ? "󰖂" : "󰈀"
            title: modelData.name
            subtitle: (modelData.type === "802-3-ethernet" ? "Wired" : modelData.type)
                + (modelData.device !== "" ? " • " + modelData.device : "")
                + (modelData.active ? " • Connected" : "")

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

    Text {
        visible: Network.profiles.length === 0
        width: parent.width
        text: root.available
            ? "No wired or VPN profiles configured (nmcli shows none)."
            : "nmcli not found — network profiles stay unmanaged here."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
    }
}
