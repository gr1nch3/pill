import QtQuick

import "../utils"

// Adapter: Bluetooth -> generic device rows + verbs for DeviceSelect.
Item {
    id: root

    readonly property string title: "Bluetooth Devices"
    readonly property bool powerOn: Bluetooth.powered
    readonly property bool powerBlocked: Bluetooth.blocked
    readonly property bool discoverable: Bluetooth.discoverable
    readonly property bool asyncConnect: true
    readonly property bool canRescan: true

    readonly property var items: {
        var list = Bluetooth.devices;
        var out = [];
        for (var i = 0; i < list.length; i++) {
            var d = list[i];
            out.push({
                label: d.name || d.address,
                value: d.address,
                devState: d.connected ? "connected" : d.bonded ? "paired" : "",
                signal: 0,
                secure: false,
                volume: 0,
                muted: false,
                group: d.bonded ? "paired" : "available",
                deviceIcon: d.icon || "",
                battery: d.batteryAvailable ? Math.round(d.battery) : -1,
                batteryAvailable: !!d.batteryAvailable,
                trusted: !!d.trusted,
                blocked: !!d.blocked,
                pairing: !!d.pairing,
                saved: false
            });
        }
        return out;
    }

    signal status(string id, string text, string kind)
    signal authRequired(string id)

    // Pairing/connect result tracking lives here, not in the view.
    property var _pending: null

    function togglePower() {
        Bluetooth.togglePower();
    }

    function connect(id, secret) {
        var d = Bluetooth.find(id);
        if (!d)
            return;
        root._pending = d;
        root.status(id, "Connecting to " + (d.name || id) + "...", "connecting");
        if (d.bonded)
            Bluetooth.connect(id);
        else
            Bluetooth.pair(id);
    }

    function disconnect(id) {
        var d = Bluetooth.find(id);
        Bluetooth.disconnect(id);
        root.status(id, "Disconnected from " + (d ? (d.name || id) : id), "success");
    }

    function forget(id) {
        Bluetooth.forget(id);
    }
    function pair(id) {
        Bluetooth.pair(id);
    }
    function cancelPair(id) {
        Bluetooth.cancelPair(id);
    }
    function toggleTrusted(id) {
        Bluetooth.toggleTrusted(id);
    }
    function toggleBlocked(id) {
        Bluetooth.toggleBlocked(id);
    }
    function rename(id, name) {
        Bluetooth.rename(id, name);
    }
    function setDiscoverable(on) {
        Bluetooth.setDiscoverable(on);
    }
    function rescan() {
        Bluetooth.startDiscovery();
    }
    function openSettings() {
        settingsCmd.run();
    }
    function refresh() {
    }

    Cmd {
        id: settingsCmd
        command: ["blueman-manager"]
        autorun: false
    }

    Connections {
        target: root._pending
        function onBondedChanged() {
            if (root._pending && root._pending.bonded)
                root._pending.connected = true;
        }
        function onConnectedChanged() {
            var d = root._pending;
            if (!d)
                return;
            root._pending = null;
            if (d.connected)
                root.status(d.address, "✓ Connected to " + (d.name || d.address), "success");
            else
                root.status(d.address, "✗ Failed to connect to " + (d.name || d.address), "error");
        }
    }
}
