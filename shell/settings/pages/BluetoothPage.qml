import QtQuick

import "../../services"
import "../../components"
import "../controls"

SettingsPage {
    id: root

    function toggleDevice(d) {
        if (d.connected) Bluetooth.disconnect(d.address)
        else if (d.bonded) Bluetooth.connect(d.address)
        else Bluetooth.pair(d.address)
    }

    SettingSection { icon: "󰂯"; label: "BLUETOOTH" }

    SettingRow {
        icon: Bluetooth.powered ? "󰂯" : "󰂲"
        title: "Bluetooth"
        subtitle: Bluetooth.blocked ? "Blocked by rfkill"
            : (Bluetooth.adapter ? (Bluetooth.adapter.name || "Adapter") + " • " + (Bluetooth.powered ? "On" : "Off") : "No adapter")
        SettingToggle {
            checked: Bluetooth.powered
            onToggled: Bluetooth.togglePower()
        }
    }

    SettingRow {
        icon: "󰂯"
        title: "Discoverable"
        subtitle: "Let nearby devices find this computer"
        SettingToggle {
            checked: Bluetooth.discoverable
            onToggled: Bluetooth.setDiscoverable(!Bluetooth.discoverable)
        }
    }

    Repeater {
        model: Bluetooth.devices

        SettingRow {
            id: devRow
            required property var modelData
            icon: modelData.connected ? "󰂱" : "󰂯"
            title: modelData.name || modelData.address
            subtitle: (modelData.connected ? "Connected" : modelData.bonded ? "Paired" : "Available")
                + (modelData.batteryAvailable ? " • " + Math.round(modelData.battery) + "%" : "")

            SettingAction {
                label: devRow.modelData.connected ? "Disconnect" : (devRow.modelData.bonded ? "Connect" : "Pair")
                accent: devRow.modelData.connected
                onClicked: root.toggleDevice(devRow.modelData)
            }

            SettingAction {
                visible: devRow.modelData.bonded && !devRow.modelData.connected
                label: "Forget"
                onClicked: Bluetooth.forget(devRow.modelData.address)
            }
        }
    }

    Text {
        visible: Bluetooth.devices.length === 0
        width: parent.width
        text: Bluetooth.powered ? "No devices discovered or paired yet" : "Bluetooth is off"
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
    }
}
