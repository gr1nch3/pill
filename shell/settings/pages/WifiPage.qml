import QtQuick
import "../../components"

import "../../services"
import "../controls"

SettingsPage {
    id: root

    property string connectingSsid: ""
    property string pendingSsid: ""
    property string passwordText: ""
    property string errorText: ""
    property bool _authFailed: false

    readonly property var networks: {
        var aps = [...Network.accessPoints]
        aps.sort(function(a, b) {
            if (a.active !== b.active) return a.active ? -1 : 1
            return b.signal - a.signal
        })
        return aps
    }

    function refresh() {
        if (!Integrations.has("nmcli")) return
        Network.rescan()
    }

    function connect(ap) {
        errorText = ""
        if (ap.active) return
        if (ap.saved || !ap.secure || ap.security === "" || ap.security === "--") {
            connectingSsid = ap.ssid
            Network.connectToNetwork(ap.ssid, "")
        } else {
            pendingSsid = ap.ssid
            passwordText = ""
        }
    }

    function connectWithPassword() {
        if (pendingSsid === "") return
        connectingSsid = pendingSsid
        Network.connectToNetwork(pendingSsid, passwordText)
        pendingSsid = ""
        passwordText = ""
    }

    function forget(ssid) {
        Network.forgetNetwork(ssid)
    }

    Connections {
        target: Network
        function onConnectSucceeded(ssid) {
            root.connectingSsid = ""
            root.pendingSsid = ""
            root.errorText = ""
        }
        function onConnectFailed(ssid, error) {
            root.connectingSsid = ""
            if (root._authFailed) {
                root._authFailed = false
                root.pendingSsid = ssid
                root.passwordText = ""
                return
            }
            root.errorText = ssid + ": " + String(error || "Connection failed")
        }
        function onAuthRequired(ssid) {
            root._authFailed = true
        }
    }

    SettingSection { icon: "󰖩"; label: "WI-FI" }

    SettingRow {
        icon: Network.wifiEnabled ? "󰖩" : "󰖪"
        title: "Wi-Fi"
        subtitle: Network.connected
            ? Network.wifiName + " • " + Network.signalStrength + "%"
            : (Network.wifiEnabled ? "Disconnected" : "Off")
        SettingToggle {
            checked: Network.wifiEnabled
            onToggled: Network.toggleWifi()
        }
    }

    SettingRow {
        visible: root.pendingSsid !== ""
        icon: "󰌆"
        title: "Password for " + root.pendingSsid
        subtitle: root.errorText !== "" ? root.errorText : "WPA/WPA2 password"
        TextInput {
            id: passwordInput
            width: 180
            color: Theme.text
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            clip: true
            echoMode: TextInput.Password
            text: root.passwordText
            onTextChanged: root.passwordText = text
            onAccepted: root.connectWithPassword()
            Component.onCompleted: forceActiveFocus()
        }
        SettingAction { label: "Connect"; accent: true; onClicked: root.connectWithPassword() }
        SettingAction { label: "Cancel"; onClicked: { root.pendingSsid = ""; root.passwordText = "" } }
    }

    SettingNote {
        tone: "danger"
        visible: root.errorText !== "" && root.pendingSsid === ""
        text: root.errorText
    }

    Repeater {
        model: root.networks

        SettingRow {
            id: apRow
            required property var modelData
            icon: modelData.active ? "󰤨" : (modelData.signal > 60 ? "󰤨" : modelData.signal > 30 ? "󰤥" : "󰤢")
            title: modelData.ssid
            subtitle: modelData.signal + "%"
                + (modelData.secure ? " • Secured" : " • Open")
                + (modelData.saved ? " • Saved" : "")
                + (modelData.active ? " • Connected" : "")

            SettingAction {
                visible: !apRow.modelData.active && !apRow.modelData.saved && apRow.modelData.secure && apRow.modelData.security !== "" && apRow.modelData.security !== "--"
                label: "Connect"
                onClicked: root.connect(apRow.modelData)
            }
            SettingAction {
                visible: !apRow.modelData.active && (apRow.modelData.saved || !apRow.modelData.secure || apRow.modelData.security === "" || apRow.modelData.security === "--")
                label: root.connectingSsid === apRow.modelData.ssid ? "Connecting..." : "Connect"
                accent: !apRow.modelData.saved
                onClicked: root.connect(apRow.modelData)
            }
            SettingAction {
                visible: apRow.modelData.saved && !apRow.modelData.active
                label: "Forget"
                onClicked: root.forget(apRow.modelData.ssid)
            }
            SettingAction {
                visible: apRow.modelData.active
                label: "Disconnect"
                accent: true
                onClicked: Network.disconnect()
            }
        }
    }

    SettingNote {
        visible: root.networks.length === 0
        text: Network.wifiEnabled ? "Scanning for networks..." : "Wi-Fi is off"
    }

}
