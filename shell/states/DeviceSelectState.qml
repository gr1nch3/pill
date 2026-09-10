import QtQuick
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Bluetooth

import "../services"
import "../components"
import "../utils"
import "../eyes"

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 16

    opacity: IslandState.state === "connectivity" || IslandState.state === "audiodevice" ? 1 : 0
    visible: opacity > 0
    focus: visible
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Keys.onEscapePressed: IslandState.open("controlcenter")

    property string deviceType: IslandState.deviceSelectType
    property string selectedValue: ""
    property bool powerOn: false
    property bool powerBlocked: false
    property bool _btPendingUnblock: false
    // Which bluetooth device row is expanded to show its details ("" = none)
    property string expandedValue: ""
    // Inline rename target ('' = no active rename field)
    property string _renameValue: ""
    // rfkill-driven unblock for a "blocked" device toggle
    property string _btPendingUnblockDevice: ""
    readonly property bool discoverable: deviceType === "bluetooth" && Bluetooth.defaultAdapter
        ? Bluetooth.defaultAdapter.discoverable
        : false

    // Map BlueZ icon names to Nerd Font glyphs
    function deviceGlyph(icon) {
        if (!icon) return ""
        var i = icon.toLowerCase()
        if (i.indexOf("audio-headset") !== -1 || i.indexOf("headphone") !== -1) return ""
        if (i.indexOf("audio-card") !== -1 || i.indexOf("speaker") !== -1) return ""
        if (i.indexOf("input-keyboard") !== -1) return ""
        if (i.indexOf("input-mouse") !== -1) return ""
        if (i.indexOf("phone") !== -1) return ""
        if (i.indexOf("computer") !== -1 || i.indexOf("laptop") !== -1) return ""
        if (i.indexOf("camera") !== -1) return ""
        if (i.indexOf("watch") !== -1) return ""
        return ""
    }

    function findBtDevice(address) {
        var devices = Bluetooth.devices.values
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].address === address) return devices[i]
        }
        return null
    }

    Process {
        id: btRfkillProc
        command: ["rfkill", "unblock", "bluetooth"]
        running: false
        onExited: {
            if (root._btPendingUnblock) {
                root._btPendingUnblock = false
                btRetryTimer.start()
            }
        }
    }

    Timer {
        id: btRetryTimer
        interval: 600
        onTriggered: {
            var adapter = Bluetooth.defaultAdapter
            if (adapter) adapter.enabled = true
        }
    }

    // WiFi password state
    property bool passwordRequired: false
    property string pendingSsid: ""
    property string passwordInput: ""
    property string connectError: ""
    property bool connecting: false

    // Connection state feedback
    property string connectingValue: ""
    property var pendingDevice: null
    property string connectStatus: ""
    property string connectStatusType: "" // "connecting", "success", "error"
    property var _errorMap: ({})

    // Bluetooth device tracking
    property var btDevices: []
    property bool _initialized: false
    property bool _scanning: false

    onDeviceTypeChanged: {
        _initialized = false
        resetPasswordState()
        connectingValue = ""
        connectStatus = ""
        connectStatusType = ""
        _errorMap = ({})
        syncPower()
        syncDevices()
        _initialized = true
    }
    onVisibleChanged: {
        if (visible && !_initialized) {
            resetPasswordState()
            connectingValue = ""
            connectStatus = ""
            connectStatusType = ""
            syncPower()
            syncDevices()
            _initialized = true
        }
    }

    function resetPasswordState() {
        passwordRequired = false
        pendingSsid = ""
        passwordInput = ""
        connectError = ""
        connecting = false
    }

    function syncPower() {
        if (deviceType === "wifi") {
            root.powerOn = Network.wifiEnabled
            root.powerBlocked = false
        } else if (deviceType === "bluetooth") {
            var adapter = Bluetooth.defaultAdapter
            root.powerOn = adapter ? adapter.enabled : false
            root.powerBlocked = adapter ? adapter.state === 4 : false
        }
    }

    function syncDevices() {
        if (deviceType === "wifi") {
            var aps = Network.accessPoints.slice()
            aps.sort(function(a, b) {
                if (a.active !== b.active) return a.active ? -1 : 1
                return b.signal - a.signal
            })
            _syncList(aps, function(ap) {
                return {
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
                }
            })
        } else if (deviceType === "bluetooth") {
            var devices = [...Bluetooth.devices.values]
            devices.sort(function(a, b) {
                return (b.connected ? 2 : b.bonded ? 1 : 0) - (a.connected ? 2 : a.bonded ? 1 : 0)
                    || a.name.localeCompare(b.name)
            })
            _syncList(devices, function(d) {
                return {
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
                }
            })
        } else if (deviceType === "audio") {
            fetchSinks()
        } else if (deviceType === "mic") {
            fetchSources()
        }
    }

    function _syncList(sourceArray, mapFn) {
        // Build index of existing model items by value
        var existing = {}
        for (var i = deviceListModel.count - 1; i >= 0; i--) {
            var item = deviceListModel.get(i)
            existing[item.value] = i
        }
        // Track which source values are present
        var seen = {}
        var ordered = []
        var setChanged = false
        for (var j = 0; j < sourceArray.length; j++) {
            var entry = mapFn(sourceArray[j])
            ordered.push(entry)
            seen[entry.value] = true
            if (typeof existing[entry.value] === "number") {
                var idx = existing[entry.value]
                for (var key in entry)
                    deviceListModel.setProperty(idx, key, entry[key])
            } else {
                setChanged = true
                deviceListModel.append(entry)
            }
        }
        // Detect stale items
        for (var k = deviceListModel.count - 1; k >= 0; k--) {
            if (!seen[deviceListModel.get(k).value]) {
                deviceListModel.remove(k)
                setChanged = true
            }
        }
        // Only do a destructive clear+append when the item *set* changed;
        // re-sorting on every signal jitter resets the ListView scroll.
        if (setChanged) {
            deviceListModel.clear()
            for (var l = 0; l < ordered.length; l++)
                deviceListModel.append(ordered[l])
        }
    }

    function fetchSinks() {
        deviceListModel.clear()
        sinkProc.command = ["bash", "-c",
            "cur=$(pactl get-default-sink 2>/dev/null); " +
            "pactl --format=json list sinks 2>/dev/null | python3 -c \"" +
            "import json, sys, re\n" +
            "data = json.load(sys.stdin)\n" +
            "for s in data:\n" +
            "  vols = [int(re.sub(r'[^0-9]', '', v.get('value_percent', '0%'))) for v in s.get('volume', {}).values()]\n" +
            "  vol = max(vols) if vols else 0\n" +
            "  act = 'active' if s['name'] == '$cur' else ''\n" +
            "  mut = 'yes' if s.get('mute') else 'no'\n" +
            "  print(s['description'] + '||' + s['name'] + '||' + act + '||' + str(vol) + '||' + mut)\""]
        noDeviceTimer.restart()
        sinkProc.running = true
    }

    function fetchSources() {
        deviceListModel.clear()
        sourceProc.command = ["bash", "-c",
            "cur=$(pactl get-default-source 2>/dev/null); " +
            "pactl --format=json list sources 2>/dev/null | python3 -c \"" +
            "import json, sys, re\n" +
            "data = json.load(sys.stdin)\n" +
            "for s in data:\n" +
            "  if '.monitor' in s.get('name', ''): continue\n" +
            "  vols = [int(re.sub(r'[^0-9]', '', v.get('value_percent', '0%'))) for v in s.get('volume', {}).values()]\n" +
            "  vol = max(vols) if vols else 0\n" +
            "  act = 'active' if s['name'] == '$cur' else ''\n" +
            "  mut = 'yes' if s.get('mute') else 'no'\n" +
            "  print(s['description'] + '||' + s['name'] + '||' + act + '||' + str(vol) + '||' + mut)\""]
        noDeviceTimer.restart()
        sourceProc.running = true
    }

    function togglePower() {
        if (deviceType === "wifi") {
            Network.toggleWifi()
            root.powerOn = !root.powerOn
        } else if (deviceType === "bluetooth") {
            var adapter = Bluetooth.defaultAdapter
            if (!adapter) return
            if (adapter.state === 4 /* Blocked */) {
                root._btPendingUnblock = true
                btRfkillProc.running = true
            } else {
                adapter.enabled = !adapter.enabled
                root.powerOn = adapter.enabled
            }
        }
    }

    function performConnect(value) {
        if (deviceType === "wifi") {
            root.connecting = true
            root.connectError = ""
            root.connectingValue = value
            root.connectStatus = "Connecting to " + value + "..."
            root.connectStatusType = "connecting"
            Network.connectToNetwork(value, root.passwordInput)
        } else if (deviceType === "bluetooth") {
            var devices = Bluetooth.devices.values
            for (var i = 0; i < devices.length; i++) {
                if (devices[i].address === value) {
                    root.connectingValue = value
                    root.pendingDevice = devices[i]
                    root.connectStatus = "Connecting to " + (devices[i].name || value) + "..."
                    root.connectStatusType = "connecting"
                    if (devices[i].bonded) {
                        devices[i].connected = true
                    } else {
                        devices[i].pair()
                    }
                    break
                }
            }
        } else if (deviceType === "audio") {
            root.selectedValue = value
            actionProc.command = ["pactl", "set-default-sink", value]
            actionProc.running = true
        } else if (deviceType === "mic") {
            root.selectedValue = value
            actionProc.command = ["pactl", "set-default-source", value]
            actionProc.running = true
        }
    }

    function performDisconnect(value) {
        if (deviceType === "wifi") {
            root.connectStatus = "Disconnected"
            root.connectStatusType = "success"
            root.connectingValue = ""
            Network.disconnect()
            statusTimer.restart()
        } else if (deviceType === "bluetooth") {
            var devices = Bluetooth.devices.values
            for (var i = 0; i < devices.length; i++) {
                if (devices[i].address === value) {
                    devices[i].connected = false
                    root.connectStatus = "Disconnected from " + (devices[i].name || value)
                    root.connectStatusType = "success"
                    root.connectingValue = ""
                    statusTimer.restart()
                    break
                }
            }
        }
    }

    function performForget(value) {
        if (deviceType === "wifi") {
            delete root._errorMap[value]
            Network.forgetNetwork(value)
        } else if (deviceType === "bluetooth") {
            var devices = Bluetooth.devices.values
            for (var i = 0; i < devices.length; i++) {
                if (devices[i].address === value) {
                    devices[i].forget()
                    break
                }
            }
        }
    }

    function performPair(value) {
        if (deviceType === "bluetooth") {
            var devices = Bluetooth.devices.values
            for (var i = 0; i < devices.length; i++) {
                if (devices[i].address === value) {
                    devices[i].pair()
                    break
                }
            }
        }
    }

    function performCancelPair(value) {
        if (deviceType === "bluetooth") {
            root.findBtDevice(value)?.cancelPair()
        }
    }

    function toggleTrust(value) {
        if (deviceType === "bluetooth") {
            var d = root.findBtDevice(value)
            if (d) d.trusted = !d.trusted
        }
    }

    function toggleBlock(value) {
        if (deviceType === "bluetooth") {
            var d = root.findBtDevice(value)
            if (d) d.blocked = !d.blocked
            if (value === root.expandedValue) root.expandedValue = ""
        }
    }

    function applyRename(value, name) {
        if (deviceType === "bluetooth") {
            var d = root.findBtDevice(value)
            if (d && name.trim() !== "") d.name = name.trim()
        }
        root._renameValue = ""
    }

    function toggleDiscoverable() {
        var adapter = Bluetooth.defaultAdapter
        if (adapter) adapter.discoverable = !adapter.discoverable
    }

    ListModel {
        id: deviceListModel
        dynamicRoles: true
    }

    // Sink process — pactl list sinks
    Process {
        id: sinkProc
        command: []; running: false
        stdout: SplitParser { onRead: function(line) { updateModelFromLine(line) } }
    }

    // Source process — pactl list sources
    Process {
        id: sourceProc
        command: []; running: false
        stdout: SplitParser { onRead: function(line) { updateModelFromLine(line) } }
    }

    // Fallback: show "(no devices found)" if process finishes with empty model
    Timer {
        id: noDeviceTimer
        interval: 3000
        running: false
        onTriggered: {
            if (deviceListModel.count === 0) {
                deviceListModel.append({ label: "(no devices found)", value: "", devState: "", signal: 0, secure: false, volume: 0, muted: false, group: "", deviceIcon: "", battery: -1, batteryAvailable: false, trusted: false, blocked: false, pairing: false, saved: false })
            }
        }
    }

    function updateModelFromLine(line) {
        var parts = line.split("||")
        if (parts.length >= 2 && parts[0].trim() !== "") {
            noDeviceTimer.stop()
            var label = parts[0].trim()
            var value = parts[1].trim()
            var state = parts.length >= 3 ? parts[2].trim() : ""
            var vol = parts.length >= 4 ? parseInt(parts[3]) || 0 : 0
            var mut = parts.length >= 5 ? parts[4].trim() === "yes" : false
            var idx = -1
            for (var i = 0; i < deviceListModel.count; i++) {
                if (deviceListModel.get(i).value === value) { idx = i; break }
            }
            if (idx >= 0) {
                deviceListModel.setProperty(idx, "label", label)
                deviceListModel.setProperty(idx, "devState", state)
                deviceListModel.setProperty(idx, "volume", vol)
                deviceListModel.setProperty(idx, "muted", mut)
            } else {
                deviceListModel.append({
                    label: label, value: value, devState: state,
                    signal: 0, secure: false, volume: vol, muted: mut,
                    group: "", deviceIcon: "", battery: -1, batteryAvailable: false,
                    trusted: false, blocked: false, pairing: false, saved: false
                })
            }
        }
    }

    Process { id: actionProc; command: []; running: false }
    Process { id: settingsProc; command: []; running: false }

    // Clear status banner after a timeout
    Timer {
        id: statusTimer
        interval: 3000
        running: false
        onTriggered: {
            connectStatus = ""
            connectStatusType = ""
        }
    }

    // Fallback: clear connecting state if it hangs (BT failure detection)
    Timer {
        id: connectTimeout
        interval: 15000
        running: root.connectingValue !== ""
        repeat: false
        onTriggered: {
            if (root.connectingValue !== "") {
                root.connectingValue = ""
                root.connectStatus = "✗ Connection timed out"
                root.connectStatusType = "error"
                statusTimer.restart()
            }
        }
    }
    Timer {
        id: scanTimer
        interval: 4000
        running: false
        onTriggered: root._scanning = false
    }
    Process { id: sinkVolProc; command: []; running: false }
    Process { id: sinkMuteProc; command: []; running: false }
    Process { id: sourceVolProc; command: []; running: false }
    Process { id: sourceMuteProc; command: []; running: false }

    function setSinkVolume(name, pct) {
        sinkVolProc.command = ["pactl", "set-sink-volume", name, pct + "%"]
        sinkVolProc.running = true
    }

    function toggleSinkMute(name) {
        sinkMuteProc.command = ["pactl", "set-sink-mute", name, "toggle"]
        sinkMuteProc.running = true
    }

    function setSourceVolume(name, pct) {
        sourceVolProc.command = ["pactl", "set-source-volume", name, pct + "%"]
        sourceVolProc.running = true
    }

    function toggleSourceMute(name) {
        sourceMuteProc.command = ["pactl", "set-source-mute", name, "toggle"]
        sourceMuteProc.running = true
    }

    property var activeDevice: {
        if (root.deviceType !== "audio" && root.deviceType !== "mic") return null
        for (var i = 0; i < deviceListModel.count; i++) {
            var d = deviceListModel.get(i)
            if (d.devState === "active") return d
        }
        return deviceListModel.count > 0 ? deviceListModel.get(0) : null
    }

    function getTitle() {
        if (deviceType === "wifi") return "Wi-Fi Networks"
        if (deviceType === "bluetooth") return "Bluetooth Devices"
        if (deviceType === "audio") return "Audio Outputs"
        if (deviceType === "mic") return "Audio Inputs"
        return "Devices"
    }

    // Keep device lists and volume in sync
    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: {
            syncPower()
            if (root.deviceType === "wifi" || root.deviceType === "bluetooth") {
                syncDevices()
            } else if (root.deviceType === "audio") {
                sinkProc.running = false
                sinkProc.running = true
            } else if (root.deviceType === "mic") {
                sourceProc.running = false
                sourceProc.running = true
            }
        }
    }

    function rescanWifi() {
        root._scanning = true
        scanTimer.restart()
        if (root.deviceType === "wifi") {
            Network.rescan()
        } else if (root.deviceType === "bluetooth") {
            var adapter = Bluetooth.defaultAdapter
            if (adapter) adapter.startDiscovery()
        }
    }

    function openSettings() {
        if (root.deviceType === "wifi") {
            settingsProc.command = ["nm-connection-editor"]
        } else if (root.deviceType === "bluetooth") {
            settingsProc.command = ["blueman-manager"]
        }
        settingsProc.running = true
    }

    // Connect result handling
    Connections {
        target: Network
        function onConnectSucceeded(ssid) {
            if (root.deviceType === "wifi") {
                root.connecting = false
                root.passwordRequired = false
                root.passwordInput = ""
                root.pendingSsid = ""
                root.connectError = ""
                root.connectingValue = ""
                root.connectStatus = "✓ Connected to " + ssid
                root.connectStatusType = "success"
                // Clear any previous error for this network
                delete root._errorMap[ssid]
                statusTimer.restart()
            }
        }
        function onConnectFailed(ssid, error) {
            if (root.deviceType === "wifi") {
                var errMsg = error || "Connection failed"
                root.connecting = false
                // If nmcli needs a password, show the password prompt
                if (!root.passwordRequired && (errMsg.toLowerCase().indexOf("secrets") !== -1 || errMsg.toLowerCase().indexOf("password") !== -1 || errMsg.toLowerCase().indexOf("key-mgmt") !== -1)) {
                    root.connectingValue = ""
                    root.passwordRequired = true
                    root.pendingSsid = ssid
                    root.passwordInput = ""
                    root.connectError = ""
                    root.connectStatus = " Password required for " + ssid
                    root.connectStatusType = "connecting"
                    statusTimer.restart()
                } else {
                    root.connectingValue = ""
                    root.connectError = errMsg
                    root.connectStatus = "✗ " + ssid + ": " + errMsg
                    root.connectStatusType = "error"
                    statusTimer.restart()
                    root._errorMap[ssid] = errMsg
                }
            }
        }
    }

    // Track Bluetooth connection results via per-device property changes
    // (the Bluetooth singleton itself only emits defaultAdapterChanged)
    Connections {
        target: root.pendingDevice
        function onBondedChanged() {
            if (root.deviceType === "bluetooth" && root.pendingDevice && root.pendingDevice.address === root.connectingValue && root.pendingDevice.bonded) {
                // After pairing succeeds, try to connect
                root.pendingDevice.connected = true
            }
        }
        function onConnectedChanged() {
            if (root.deviceType === "bluetooth" && root.pendingDevice && root.pendingDevice.address === root.connectingValue) {
                if (root.pendingDevice.connected) {
                    root.connectStatus = "✓ Connected to " + (root.pendingDevice.name || root.pendingDevice.address)
                    root.connectStatusType = "success"
                } else {
                    root.connectStatus = "✗ Failed to connect to " + (root.pendingDevice.name || root.pendingDevice.address)
                    root.connectStatusType = "error"
                }
                statusTimer.restart()
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Row {
            width: parent.width
            spacing: 8

            BackButton {
                id: backBtn
                anchors.verticalCenter: parent.verticalCenter
                onClicked: IslandState.open("controlcenter")
            }

            Eye {
                id: devEyes
                eyeWidth: 18; eyeHeight: 13; eyeSpacing: 7
                anchors.verticalCenter: parent.verticalCenter
                moods: Theme.eyeMoods
                mood: "active"
            }

            Text {
                id: titleText
                text: root.getTitle()
                color: Theme.text
                font.pixelSize: Theme.font.size.normal
                font.family: Theme.font.family
                font.weight: 600
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Math.max(1, parent.width - backBtn.implicitWidth - devEyes.width - titleText.implicitWidth - (headerBtns.visible ? headerBtns.width + 8 : 0) - 44)
                height: 1; anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                id: headerBtns
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: root.deviceType === "wifi" || root.deviceType === "bluetooth"

                Rectangle {
                    width: 32; height: 32; radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: scanHeaderBtn.containsMouse ? Theme.highlight : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: root._scanning ? Theme.accent : Theme.subtext
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.mono
                        rotation: 0
                        NumberAnimation on rotation {
                            from: 0; to: 360; duration: 1000
                            running: root._scanning
                            loops: Animation.Infinite
                        }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: scanHeaderBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.rescanWifi()
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: setHeaderBtn.containsMouse ? Theme.highlight : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.mono
                    }

                    MouseArea {
                        id: setHeaderBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openSettings()
                    }
                }

                Rectangle {
                    id: discoverBtn
                    width: 32; height: 32; radius: 8
                    visible: root.deviceType === "bluetooth"
                    anchors.verticalCenter: parent.verticalCenter
                    color: discoverHeaderBtn.containsMouse || root.discoverable ? Theme.highlight : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.discoverable ? "" : ""
                        color: root.discoverable ? Theme.accent : Theme.subtext
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.mono
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: discoverHeaderBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleDiscoverable()
                    }
                }

                Rectangle {
                    id: toggleTrack
                    width: 40; height: 24; radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.powerOn ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        x: root.powerOn ? toggleTrack.width - width - 2 : 2
                        y: 2; width: 20; height: 20; radius: 10
                        color: Theme.background
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePower()
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            visible: root.connectStatus !== ""
            height: root.connectStatus !== "" ? 28 : 0
            radius: 8
            color: root.connectStatusType === "success" ? "#2020aa30"
                 : root.connectStatusType === "error" ? "#30ff2020"
                 : Theme.highlight
            Behavior on height { NumberAnimation { duration: 120 } }

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: root.connectStatusType === "success" ? ""
                        : root.connectStatusType === "error" ? ""
                        : ""
                    color: root.connectStatusType === "success" ? "#40d080"
                         : root.connectStatusType === "error" ? Theme.danger
                         : Theme.accent
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.mono
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.connectStatus
                    color: root.connectStatusType === "success" ? "#80e0a0"
                         : root.connectStatusType === "error" ? Theme.danger
                         : Theme.subtext
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.family
                    font.weight: 500
                    elide: Text.ElideRight
                    width: parent.parent.width - 30
                }
            }

            Text {
                text: "✕"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.mono
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 6
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { root.connectStatus = ""; root.connectStatusType = "" }
                }
            }
        }

        Item {
            id: listArea
            width: parent.width
            height: parent.height - 40 - (root.connectStatus !== "" ? 32 : 0)

            ListView {
                id: deviceList
                anchors.fill: parent
                clip: true
                model: deviceListModel
                spacing: 4

                section.property: "group"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle {
                    readonly property string _secTitle: {
                        if (section === "paired") return "PAIRED DEVICES"
                        if (section === "available") return "AVAILABLE DEVICES"
                        return ""
                    }
                    width: ListView.view.width
                    height: _secTitle !== "" ? 22 : 0
                    color: "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 4
                        text: parent._secTitle
                        visible: parent._secTitle !== ""
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.caption
                        font.family: Theme.font.family
                        font.weight: 600
                    }
                }

            delegate: Rectangle {
                required property string label
                required property string value
                required property string devState
                required property int signal
                required property bool secure
                required property int volume
                required property bool muted
                required property string group
                required property string deviceIcon
                required property int battery
                required property bool batteryAvailable
                required property bool pairing
                required property bool saved
                required property bool trusted
                required property bool blocked

                readonly property bool isActive: devState === "active" || devState === "connected"
                readonly property bool connecting: root.connectingValue === value
                readonly property string errorText: root._errorMap[value] || ""
                readonly property bool expanded: root.deviceType === "bluetooth" && root.expandedValue === value

                width: ListView.view.width
                height: (root.deviceType === "audio" || root.deviceType === "mic") ? 52
                      : (expanded ? 150 : errorText !== "" ? 62 : connecting ? 62 : 46)
                radius: 12
                color: isActive ? Theme.highlight : itemMouse.containsMouse ? Theme.surfaceHover : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }

                Item {
                    anchors.top: parent.top
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.right: parent.right; anchors.rightMargin: 8
                    height: expanded ? 46 : parent.height

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        color: isActive ? Theme.accent : "transparent"
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 18
                        anchors.right: (root.deviceType === "wifi" || root.deviceType === "bluetooth") ? actionsRow.left : parent.right
                        anchors.rightMargin: 4
                        spacing: 1

                        Row {
                            width: parent.width
                            spacing: 5

                            Text {
                                visible: root.deviceType === "bluetooth"
                                text: root.deviceGlyph(deviceIcon)
                                color: Theme.accent
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.mono
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                            }

                            Text {
                                text: label
                                color: connecting ? Theme.accent : Theme.text
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.family
                                font.weight: isActive ? 600 : 400
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - (root.deviceType === "bluetooth" ? 14 + (batteryAvailable ? batteryText.width + 5 : 0) : (batteryAvailable ? batteryText.width + 5 : 0))
                            }

                            Text {
                                id: batteryText
                                visible: batteryAvailable
                                text: battery + "%"
                                color: battery <= 20 ? Theme.danger : Theme.accent
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                font.weight: 500
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Row {
                            visible: connecting
                            spacing: 4

                            Text {
                                text: ""
                                color: Theme.accent
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.mono
                                RotationAnimation on rotation {
                                    from: 0; to: 360; duration: 1000
                                    running: connecting; loops: Animation.Infinite
                                }
                            }

                            Text {
                                text: "Connecting…"
                                color: Theme.accent
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                font.weight: 500
                            }
                        }

                        Text {
                            visible: errorText !== ""
                            text: " " + errorText
                            color: Theme.danger
                            font.pixelSize: Theme.font.size.caption
                            font.family: Theme.font.family
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            visible: root.deviceType === "audio" || root.deviceType === "mic"
                            text: value
                            color: isActive ? Theme.accent : Theme.subtext
                            font.pixelSize: Theme.font.size.caption
                            font.family: Theme.font.family
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    SignalStrength {
                        id: signalInd
                        value: signal
                        visible: root.deviceType === "wifi" && signal > 0
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: actionsRow.left
                        anchors.rightMargin: 4
                    }

                    // Action buttons (wifi/bluetooth only)
                    Row {
                        id: actionsRow
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        visible: root.deviceType === "wifi" || root.deviceType === "bluetooth"

                        Repeater {
                            model: {
                                if (root.deviceType === "wifi") {
                                    if (devState === "connected") return saved ? ["disconnect", "remove"] : ["disconnect"]
                                    return saved ? ["connect", "remove"] : ["connect"]
                                }
                                if (root.deviceType === "bluetooth") {
                                    if (pairing) return ["cancel", "remove"]
                                    if (devState === "connected") return ["disconnect"]
                                    if (devState === "paired") return ["connect", "remove"]
                                    return ["pair", "connect", "remove"]
                                }
                                return []
                            }
                            delegate: Rectangle {
                                required property string modelData
                                width: 30; height: 26; radius: 6
                                color: btnMouse.pressed
                                    ? (modelData === "disconnect" || modelData === "remove" || modelData === "cancel" ? Qt.lighter(Theme.danger, 1.3) : Qt.lighter(Theme.accent, 1.3))
                                    : btnMouse.containsMouse
                                    ? (modelData === "disconnect" || modelData === "remove" || modelData === "cancel" ? Theme.danger : Theme.accent)
                                    : (modelData === "disconnect" || modelData === "remove" || modelData === "cancel" ? "#30ff0000" : "#40ffffff")
                                Behavior on color { ColorAnimation { duration: 80 } }

                                Text {
                                    text: modelData === "connect" ? ""
                                        : modelData === "disconnect" ? ""
                                        : modelData === "remove" ? ""
                                        : modelData === "pair" ? ""
                                        : modelData === "cancel" ? ""
                                        : ""
                                    color: btnMouse.pressed ? Theme.background : Theme.text
                                    font.pixelSize: Theme.font.size.small
                                    font.family: Theme.font.mono
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (value === "") return
                                        if (root.deviceType === "wifi") {
                                            if (modelData === "connect") {
                                                root.connectError = ""
                                                root.connecting = true
                                                root.performConnect(value)
                                            } else if (modelData === "disconnect") {
                                                root.performDisconnect(value)
                                            } else if (modelData === "remove") {
                                                root.performForget(value)
                                            }
                                        } else if (root.deviceType === "bluetooth") {
                                            if (modelData === "connect") root.performConnect(value)
                                            else if (modelData === "disconnect") root.performDisconnect(value)
                                            else if (modelData === "remove") root.performForget(value)
                                            else if (modelData === "pair") root.performPair(value)
                                            else if (modelData === "cancel") root.performCancelPair(value)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (value === "") return
                        if (root.deviceType === "audio" || root.deviceType === "mic") {
                            root.performConnect(value)
                        } else if (root.deviceType === "wifi") {
                            root.connectError = ""
                            root.connecting = true
                            root.performConnect(value)
                        } else if (root.deviceType === "bluetooth") {
                            // Row click toggles the detail panel; connect is an
                            // explicit action button so pairing isn't triggered
                            // by accident while scanning the list.
                            root.expandedValue = root.expandedValue === value ? "" : value
                            root._renameValue = ""
                        }
                    }
                }

                // ── Expandable bluetooth detail panel ──────────────────────
                Item {
                    visible: expanded
                    anchors.left: parent.left; anchors.leftMargin: 18
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.top: parent.top; anchors.topMargin: 46
                    height: 94

                    Column {
                        anchors.fill: parent
                        spacing: 6

                        Row {
                            width: parent.width; spacing: 6

                            Text {
                                text: value
                                color: Theme.subtext
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.mono
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                width: parent.width - (pairing ? 120 : (trusted ? 24 : 0))
                            }

                            Text {
                                visible: pairing
                                text: "pairing…"
                                color: Theme.accent
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                font.weight: 500
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                visible: trusted
                                text: ""
                                color: Theme.accent
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.mono
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.border
                            opacity: 0.4
                        }

                        Row {
                            id: detailBtns
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: root._renameValue === value
                                    ? ["save"]
                                    : ["trust", "block", "rename", "forget"]
                                delegate: Rectangle {
                                    required property string modelData
                                    readonly property bool destructive: modelData === "forget" || modelData === "block"
                                    readonly property bool active: (modelData === "trust" && trusted) || (modelData === "block" && blocked)

                                    width: detailBtns.width / 4 - 4.5
                                    height: 28
                                    radius: 7
                                    color: detailBtnMouse.containsMouse || active
                                        ? (destructive ? Theme.danger : Theme.accent)
                                        : (destructive ? "#30ff0000" : "#40ffffff")
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData === "forget" ? "Forget"
                                            : modelData === "rename" ? "Rename"
                                            : modelData === "save" ? "Save"
                                            : modelData === "block" ? (blocked ? "Unblock" : "Block")
                                            : (trusted ? "Untrust" : "Trust")
                                        color: detailBtnMouse.containsMouse || active ? Theme.background : Theme.text
                                        font.pixelSize: Theme.font.size.caption
                                        font.family: Theme.font.family
                                        font.weight: 500
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        width: parent.width
                                    }

                                    MouseArea {
                                        id: detailBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData === "trust") root.toggleTrust(value)
                                            else if (modelData === "block") root.toggleBlock(value)
                                            else if (modelData === "rename") root._renameValue = value
                                            else if (modelData === "forget") {
                                                root.performForget(value)
                                                if (root.expandedValue === value) root.expandedValue = ""
                                            } else if (modelData === "save") root.applyRename(value, renameField.text)
                                        }
                                    }
                                }
                            }
                        }

                        TextInput {
                            id: renameField
                            visible: root._renameValue === value
                            width: parent.width
                            height: 24
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.text
                            font.pixelSize: Theme.font.size.caption
                            font.family: Theme.font.family
                            text: label
                            selectByMouse: true
                            Keys.onReturnPressed: root.applyRename(value, text)
                            Keys.onEscapePressed: root._renameValue = ""
                        }
                    }
                }
            }

            // Bottom overlay stack (volume then password)
            Item {
                id: bottomStack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: {
                    var h = 0
                    if (root.activeDevice && (root.deviceType === "audio" || root.deviceType === "mic"))
                        h += 170
                    if (root.passwordRequired && root.deviceType === "wifi")
                        h += 76
                    return h
                }

                // Volume control section (audio/mic only)
                Rectangle {
                    id: volSection
                    visible: root.activeDevice !== null && (root.deviceType === "audio" || root.deviceType === "mic")
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: root.passwordRequired && root.deviceType === "wifi" ? pwdArea.top : parent.bottom
                    height: 164
                    radius: 12
                    color: Theme.background

                    Column {
                        anchors.fill: parent; anchors.margins: 12
                        spacing: 6

                        Row {
                            width: parent.width; spacing: 8

                            Text {
                                text: root.deviceType === "audio" ? "" : ""
                                font.pixelSize: Theme.font.size.large
                                font.family: Theme.font.mono
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 120
                                spacing: 1

                                Text {
                                    text: root.activeDevice ? root.activeDevice.label : ""
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.small
                                    font.family: Theme.font.family
                                    font.weight: 500
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    visible: root.activeDevice !== null
                                    text: root.activeDevice ? root.activeDevice.value : ""
                                    color: Theme.subtext
                                    font.pixelSize: Theme.font.size.caption
                                    font.family: Theme.font.family
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Text {
                                    text: (root.activeDevice ? root.activeDevice.volume : 0) + "%"
                                    color: (root.activeDevice && root.activeDevice.muted) ? Theme.danger : Theme.text
                                    font.pixelSize: Theme.font.size.large
                                    font.family: Theme.font.family
                                    font.weight: 700
                                    horizontalAlignment: Text.AlignRight
                                    width: 48
                                }

                                Text {
                                    text: {
                                        if (!root.activeDevice) return ""
                                        if (root.activeDevice.muted) return "Muted"
                                        var v = root.activeDevice.volume
                                        if (v === 0) return "Off"
                                        if (v <= 25) return "Low"
                                        if (v <= 50) return "Medium"
                                        if (v <= 75) return "High"
                                        return "Max"
                                    }
                                    color: {
                                        if (!root.activeDevice) return Theme.subtext
                                        if (root.activeDevice.muted) return Theme.danger
                                        var v = root.activeDevice.volume
                                        if (v === 0) return Theme.subtext
                                        if (v <= 25) return Theme.subtext
                                        if (v <= 50) return Theme.accent
                                        if (v <= 75) return Theme.accentAlt
                                        return Theme.danger
                                    }
                                    font.pixelSize: Theme.font.size.caption
                                    font.family: Theme.font.family
                                    font.weight: 500
                                    horizontalAlignment: Text.AlignRight
                                    width: 48
                                }
                            }
                        }

                        Row {
                            width: parent.width; spacing: 8

                            Slider {
                                width: parent.width - 38
                                value: root.activeDevice ? root.activeDevice.volume : 0
                                showPercent: false
                                icon: ""
                                fillColor: (root.activeDevice && root.activeDevice.muted) ? Theme.subtext : Theme.accent
                                onValueChangedByUser: function(pct) {
                                    if (root.deviceType === "audio" && root.activeDevice)
                                        root.setSinkVolume(root.activeDevice.value, pct)
                                    else if (root.deviceType === "mic" && root.activeDevice)
                                        root.setSourceVolume(root.activeDevice.value, pct)
                                }
                            }

                            Rectangle {
                                width: 30; height: 28; radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                color: muteBtn2Mouse.containsMouse
                                    ? ((root.activeDevice && root.activeDevice.muted) ? Theme.danger : Theme.highlight)
                                    : ((root.activeDevice && root.activeDevice.muted) ? "#40ff0000" : "#40ffffff")
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: (root.activeDevice && root.activeDevice.muted) ? "" : ""
                                    color: (root.activeDevice && root.activeDevice.muted) ? Theme.danger : Theme.text
                                    font.pixelSize: Theme.font.size.small; font.family: Theme.font.mono
                                }

                                MouseArea {
                                    id: muteBtn2Mouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.deviceType === "audio" && root.activeDevice)
                                            root.toggleSinkMute(root.activeDevice.value)
                                        else if (root.deviceType === "mic" && root.activeDevice)
                                            root.toggleSourceMute(root.activeDevice.value)
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width; spacing: 6

                            Repeater {
                                model: [0, 25, 50, 75, 100]
                                delegate: Rectangle {
                                    required property int modelData
                                    readonly property bool isCurrent: root.activeDevice && Math.abs(root.activeDevice.volume - modelData) <= 3

                                    width: (parent.width - 18) / 5
                                    height: 28
                                    radius: 8
                                    color: isCurrent
                                        ? Theme.accent
                                        : (presetMouse.containsMouse ? Theme.surfaceHover : Theme.background)
                                    border.width: 1
                                    border.color: isCurrent ? Theme.accent : Theme.border
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData === 0 ? "Off" : modelData + "%"
                                        color: isCurrent ? Theme.background : Theme.text
                                        font.pixelSize: Theme.font.size.caption
                                        font.family: Theme.font.family
                                        font.weight: isCurrent ? 600 : 400
                                    }

                                    MouseArea {
                                        id: presetMouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!root.activeDevice) return
                                            if (root.deviceType === "audio")
                                                root.setSinkVolume(root.activeDevice.value, modelData)
                                            else if (root.deviceType === "mic")
                                                root.setSourceVolume(root.activeDevice.value, modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Password input area (WiFi secured networks)
                Rectangle {
                    id: pwdArea
                    visible: root.passwordRequired && root.deviceType === "wifi"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 70
                    radius: 12
                    color: Theme.background

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Row {
                            width: parent.width
                            spacing: 6

                            Rectangle {
                                width: parent.width - connectBtn.width - 12
                                height: 30
                                radius: 8
                                color: Theme.surfaceHover
                                border.color: Theme.border
                                border.width: 1

                                TextInput {
                                    id: passwordField
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.small
                                    font.family: Theme.font.family
                                    echoMode: TextInput.Password
                                    passwordCharacter: "●"
                                    text: root.passwordInput
                                    focus: true
                                    onTextChanged: root.passwordInput = text
                                    onAccepted: {
                                        if (root.pendingSsid && root.passwordInput.length > 0) {
                                            root.connecting = true
                                            root.connectError = ""
                                            root.performConnect(root.pendingSsid)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: connectBtn
                                width: 60; height: 30; radius: 8
                                color: btnConnect.containsMouse ? Theme.accent : Qt.lighter(Theme.accent, 0.85)
                                Behavior on color { ColorAnimation { duration: 80 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.connecting ? "..." : "Connect"
                                    color: Theme.background
                                    font.pixelSize: Theme.font.size.small
                                    font.family: Theme.font.family
                                    font.weight: 500
                                }

                                MouseArea {
                                    id: btnConnect
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.pendingSsid && root.passwordInput.length > 0) {
                                            root.connecting = true
                                            root.connectError = ""
                                            root.performConnect(root.pendingSsid)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: root.connectError !== "" ? "Error: " + root.connectError : ""
                            color: Theme.danger
                            font.pixelSize: Theme.font.size.caption
                            font.family: Theme.font.family
                            visible: root.connectError !== ""
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: "Enter password for " + root.pendingSsid
                            color: Theme.subtext
                            font.pixelSize: Theme.font.size.caption
                            font.family: Theme.font.family
                            visible: root.connectError === ""
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Text {
                        text: "✕"
                        color: cancelHover.containsMouse ? Theme.danger : Theme.subtext
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.mono
                        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6
                        Behavior on color { ColorAnimation { duration: 80 } }
                        MouseArea {
                            id: cancelHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.passwordRequired = false
                                root.pendingSsid = ""
                                root.passwordInput = ""
                                root.connectError = ""
                                root.connecting = false
                            }
                        }
                    }
                }
            }
        }
    }
}
}
