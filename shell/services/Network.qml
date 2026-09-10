pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool connected: false
    property bool wifiEnabled: false
    property string wifiName: ""
    property int signalStrength: 0
    property var accessPoints: []

    property bool _connecting: false
    property string _connectSsid: ""

    signal connectSucceeded(string ssid)
    signal connectFailed(string ssid, string error)
    signal disconnectFinished()

    function toggleWifi() {
        var enable = !root.wifiEnabled
        toggleProc.command = ["nmcli", "radio", "wifi", enable ? "on" : "off"]
        toggleProc.running = true
        root.wifiEnabled = enable
    }

    function rescan() {
        rescanProc.running = true
    }

    function connectToNetwork(ssid, password) {
        root._connecting = true
        root._connectSsid = ssid
        var cmd = ["nmcli", "dev", "wifi", "connect", ssid]
        if (password && password.length > 0)
            cmd.push("password", password)
        connectProc.command = cmd
        connectProc.running = true
    }

    function disconnect() {
        if (root.wifiName && root.wifiName.length > 0) {
            disconnectProc.command = ["nmcli", "connection", "down", root.wifiName]
        } else {
            disconnectProc.command = ["nmcli", "dev", "disconnect", "wifi"]
        }
        disconnectProc.running = true
    }

    function forgetNetwork(ssid) {
        forgetProc.command = ["nmcli", "connection", "delete", ssid]
        forgetProc.running = true
    }

    function _refresh() {
        radioProc.running = true
        root.accessPoints = []
        listProc.running = true
        activeProc.running = true
    }

    function _quickRefresh() {
        radioProc.running = true
        activeProc.running = true
    }

    Process {
        id: radioProc
        command: ["nmcli", "-c", "no", "radio", "wifi"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                root.wifiEnabled = line.trim() === "enabled"
            }
        }
    }

    Process {
        id: listProc
        command: ["bash", "-c",
            "saved=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | sed 's/\\\\:/<N>/g' | grep ':802-11-wireless$' | sed 's/:802-11-wireless$//' | sed 's/<N>/:/g'); " +
            "nmcli -t -f ACTIVE,SIGNAL,SSID,SECURITY dev wifi list 2>/dev/null | " +
            "sed 's/\\\\:/<ESC>/g' | " +
            "while IFS=: read -r active signal ssid security; do " +
            "  [ -z \"$ssid\" ] && continue; " +
            "  [ \"$ssid\" = \"--\" ] && continue; " +
            "  ssid=$(echo \"$ssid\" | sed 's/<ESC>/:/g'); " +
            "  is_saved=no; echo \"$saved\" | grep -qxF \"$ssid\" && is_saved=yes; " +
            "  echo \"$active||$signal||$ssid||$security||$is_saved\"; done"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split("||")
                if (parts.length < 4) return
                var active = parts[0] === "*" || parts[0] === "yes"
                var signal = parseInt(parts[1]) || 0
                var ssid = parts[2].trim()
                var security = parts[3].trim()
                var saved = parts.length >= 5 && parts[4].trim() === "yes"
                if (ssid === "") return

                var aps = root.accessPoints
                for (var i = 0; i < aps.length; i++) {
                    if (aps[i].ssid === ssid) {
                        aps[i].signal = Math.max(aps[i].signal, signal)
                        aps[i].active = aps[i].active || active
                        aps[i].saved = aps[i].saved || saved
                        if (active) aps[i].security = security
                        root.accessPoints = aps
                        return
                    }
                }
                aps.push({ ssid: ssid, signal: signal, security: security, active: active, saved: saved })
                aps.sort(function(a, b) { return b.signal - a.signal })
                root.accessPoints = aps
            }
        }
    }

    Process {
        id: activeProc
        command: ["bash", "-c",
            "line=$(nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list 2>/dev/null | sed 's/\\\\:/<ESC>/g' | grep '^yes:' | head -1); " +
            "if [ -n \"$line\" ]; then " +
            "  signal=$(echo \"$line\" | cut -d: -f2); " +
            "  ssid=$(echo \"$line\" | cut -d: -f3- | sed 's/<ESC>/:/g'); " +
            "  echo \"$ssid||$signal\"; " +
            "else " +
            "  name=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -E ':(wireless|802-11-wireless)$' | head -1 | cut -d: -f1); " +
            "  echo \"${name:-}||0\"; fi"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split("||")
                root.wifiName = parts[0] ? parts[0].trim() : ""
                root.connected = root.wifiName !== ""
                root.signalStrength = parseInt(parts[1]) || 0
            }
        }
    }

    // Qt.callLater ignores its second arg (runs next tick), so replace the
    // old fn,ms pattern with one-shot debounce timers.
    Timer {
        id: refreshDebounceTimer
        interval: 500
        onTriggered: _refresh()
    }
    Timer {
        id: rescanRelistTimer
        interval: 2000
        onTriggered: {
            root.accessPoints = []
            listProc.running = true
        }
    }

    Process {
        id: toggleProc
        command: []
        running: false
        onExited: function(code) {
            if (code === 0) refreshDebounceTimer.restart()
        }
    }

    Process {
        id: connectProc
        command: []
        running: false
        property string stderrBuf: ""

        stderr: SplitParser {
            onRead: function(line) {
                var trimmed = line.trim()
                if (trimmed.length > 0)
                    connectProc.stderrBuf += trimmed + "\n"
            }
        }
        onExited: function(code) {
            root._connecting = false
            if (code === 0) {
                root.connectSucceeded(root._connectSsid)
                refreshDebounceTimer.restart()
            } else {
                root.connectFailed(root._connectSsid, connectProc.stderrBuf.trim() || "Connection failed")
            }
            connectProc.stderrBuf = ""
        }
    }

    Process {
        id: disconnectProc
        command: []
        running: false
        onExited: function(code) {
            if (code === 0) {
                root.connected = false
                root.wifiName = ""
                root.signalStrength = 0
                root.disconnectFinished()
                refreshDebounceTimer.restart()
            }
        }
    }

    Process {
        id: forgetProc
        command: []
        running: false
        onExited: function(code) {
            if (code === 0) refreshDebounceTimer.restart()
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "rescan"]
        onExited: function(code) {
            if (code === 0) rescanRelistTimer.restart()
        }
    }

    Process {
        id: monitorProc
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                refreshTimer.restart()
            }
        }
        onExited: function() {
            monitorRestartTimer.start()
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: _quickRefresh()
    }

    Timer {
        id: monitorRestartTimer
        interval: 2000
        onTriggered: {
            monitorProc.running = true
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: _refresh()
    }

    Component.onCompleted: _refresh()
}
