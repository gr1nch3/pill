import QtQuick
import "../../components"

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [
        { label: "Rescan", icon: "󰑓", accent: true, onTrigger: function() { Network.rescan() } },
        { label: "Disconnect", icon: "󰖪", visible: Network.connected, onTrigger: function() { Network.disconnect() } }
    ]

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
            pwDialog.open()
        }
    }

    function connectWithPassword() {
        if (pendingSsid === "") return
        connectingSsid = pendingSsid
        errorText = ""
        Network.connectToNetwork(pendingSsid, passwordText)
    }

    function cancelPassword() {
        pendingSsid = ""
        passwordText = ""
        errorText = ""
        pwDialog.close()
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
            if (pwDialog.opened) pwDialog.close()
        }
        function onConnectFailed(ssid, error) {
            root.connectingSsid = ""
            if (root._authFailed) {
                root._authFailed = false
                root.passwordText = ""
                root.errorText = "Authentication failed — try again"
                return
            }
            root.errorText = ssid + ": " + String(error || "Connection failed")
        }
        function onAuthRequired(ssid) {
            root._authFailed = true
        }
    }

    SettingRow {
        icon: Network.wifiEnabled ? "󰖩" : "󰖪"
        title: "Wi-Fi"
        subtitle: Network.connected
            ? Network.wifiName + " • " + Network.signalStrength + "%"
            : (Network.wifiEnabled ? "Disconnected" : "Off")
        Item {
            width: 16; height: 22
            SignalStrength {
                anchors.centerIn: parent
                value: Network.signalStrength
                visible: Network.connected
            }
        }
        SettingToggle {
            checked: Network.wifiEnabled
            onToggled: Network.toggleWifi()
        }
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
                visible: !!(!apRow.modelData.active && !apRow.modelData.saved && apRow.modelData.secure && apRow.modelData.security !== "" && apRow.modelData.security !== "--")
                label: "Connect"
                onClicked: root.connect(apRow.modelData)
            }

            Item {
                width: 16; height: 22
                SignalStrength {
                    anchors.centerIn: parent
                    value: apRow.modelData.signal
                    opacity: apRow.modelData.active ? 1 : 0.75
                }
            }
            SettingAction {
                visible: !!(!apRow.modelData.active && (apRow.modelData.saved || !apRow.modelData.secure || apRow.modelData.security === "" || apRow.modelData.security === "--"))
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

    // Password entry lives in a dialog now: the row list stays stable while a
    // connection is being set up, and the field can't be lost mid-scroll.
    SettingDialog {
        id: pwDialog
        title: "Connect to " + root.pendingSsid
        description: "This network is secured — enter its WPA/WPA2 password."

        SettingEdit {
            id: pwField
            width: parent.width
            live: true
            echoMode: TextInput.Password
            value: root.passwordText
            placeholder: "Password"
            onTextEdited: function(text) { root.passwordText = text }
            onAccepted: root.connectWithPassword()
        }

        SettingNote {
            tone: "danger"
            text: root.errorText
        }

        Item {
            width: parent.width
            height: 30

            Row {
                anchors.right: parent.right
                spacing: 8

                SettingAction { label: "Cancel"; onClicked: root.cancelPassword() }
                SettingAction {
                    label: "Connect"
                    accent: true
                    busy: root.connectingSsid !== "" && root.connectingSsid === root.pendingSsid
                    interactive: !busy
                    onClicked: root.connectWithPassword()
                }
            }
        }

        onOpened: pwField.focusInput()
    }

}
