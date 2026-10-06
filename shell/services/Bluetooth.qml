pragma Singleton
// One owner for the Bluetooth adapter: power (including the rfkill unblock
// dance), discovery, and device verbs. Views bind to `devices`, never to
// Quickshell.Bluetooth directly.
import QtQuick
import Quickshell.Bluetooth

import "../utils"

Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool powered: adapter ? adapter.enabled : false
    readonly property bool blocked: adapter ? adapter.state === 4 : false
    readonly property bool discoverable: adapter ? adapter.discoverable : false
    readonly property bool discovering: adapter ? adapter.discovering : false

    // Connected first, then paired, then by name.
    readonly property var devices: {
        var list = [...Bluetooth.devices.values];
        list.sort(function (a, b) {
            return (b.connected ? 2 : b.bonded ? 1 : 0) - (a.connected ? 2 : a.bonded ? 1 : 0) || (a.name || a.address).localeCompare(b.name || b.address);
        });
        return list;
    }

    property bool _unblockPending: false

    function find(address) {
        var list = Bluetooth.devices.values;
        for (var i = 0; i < list.length; i++)
            if (list[i].address === address)
                return list[i];
        return null;
    }

    // Blocked adapters need `rfkill unblock`, then a short settle before
    // enabling (BlueZ refuses the enable while the soft block is still up).
    function togglePower() {
        if (!adapter)
            return;
        if (adapter.state === 4) {
            _unblockPending = true;
            rfkillCmd.run();
        } else {
            adapter.enabled = !adapter.enabled;
        }
    }

    function setDiscoverable(on) {
        if (adapter)
            adapter.discoverable = on;
    }
    function startDiscovery() {
        if (adapter)
            adapter.startDiscovery();
    }
    function stopDiscovery() {
        if (adapter)
            adapter.stopDiscovery();
    }

    function connect(address) {
        var d = find(address);
        if (d)
            d.connected = true;
    }
    function disconnect(address) {
        var d = find(address);
        if (d)
            d.connected = false;
    }
    function pair(address) {
        var d = find(address);
        if (d)
            d.pair();
    }
    function cancelPair(address) {
        var d = find(address);
        if (d)
            d.cancelPair();
    }
    function forget(address) {
        var d = find(address);
        if (d)
            d.forget();
    }
    function toggleTrusted(address) {
        var d = find(address);
        if (d)
            d.trusted = !d.trusted;
    }
    function toggleBlocked(address) {
        var d = find(address);
        if (d)
            d.blocked = !d.blocked;
    }

    function rename(address, name) {
        var d = find(address);
        if (d && String(name).trim() !== "")
            d.name = String(name).trim();
    }

    Cmd {
        id: rfkillCmd
        command: ["rfkill", "unblock", "bluetooth"]
        autorun: false
        onDone: {
            if (root._unblockPending) {
                root._unblockPending = false;
                retryTimer.start();
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 600
        onTriggered: if (root.adapter)
            root.adapter.enabled = true
    }
}
