import QtQuick

import "../utils"

// Adapter: Network -> generic device rows + verbs for DeviceSelect.
Item {
    id: root

    readonly property string title: "Wi-Fi Networks"
    readonly property bool powerOn: Network.wifiEnabled
    readonly property bool powerBlocked: false
    readonly property bool asyncConnect: true
    readonly property bool canRescan: true

    readonly property var items: {
        var aps = Network.accessPoints.slice()
        aps.sort(function(a, b) {
            if (a.active !== b.active) return a.active ? -1 : 1
            return b.signal - a.signal
        })
        var out = []
        for (var i = 0; i < aps.length; i++) {
            var ap = aps[i]
            out.push({
                label: ap.ssid,
                value: ap.ssid,
                devState: ap.active ? "connected" : "",
                signal: ap.signal,
                secure: ap.security && ap.security !== "" && ap.security !== "--",
                volume: 0,
                muted: false,
                group: "",
                deviceIcon: "",
                battery: -1,
                batteryAvailable: false,
                trusted: false,
                blocked: false,
                pairing: false,
                saved: !!ap.saved
            })
        }
        return out
    }

    signal status(string id, string text, string kind)
    signal authRequired(string id)

    property bool _authPending: false

    function togglePower() { Network.toggleWifi() }
    function connect(id, secret) { Network.connectToNetwork(id, secret) }
    function disconnect(id) { Network.disconnect() }
    function forget(id) { Network.forgetNetwork(id) }
    function rescan() { Network.rescan() }
    function openSettings() { settingsCmd.run() }
    function refresh() { Network.refresh() }

    Cmd {
        id: settingsCmd
        command: ["nm-connection-editor"]
        autorun: false
    }

    Connections {
        target: Network
        function onConnectSucceeded(ssid) {
            root.status(ssid, "✓ Connected to " + ssid, "success")
        }
        function onAuthRequired(ssid) {
            root._authPending = true
            root.authRequired(ssid)
        }
        function onConnectFailed(ssid, error) {
            if (root._authPending) {
                root._authPending = false
                return
            }
            root.status(ssid, "✗ " + ssid + ": " + (error || "Connection failed"), "error")
        }
    }
}
