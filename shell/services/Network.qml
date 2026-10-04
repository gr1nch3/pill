pragma Singleton
// One owner for nmcli: radio state, access points, saved profiles, and the
// connect verbs. Views never build nmcli commands or parse its output.
import QtQuick

import "../utils"

Item {
    id: root

    property bool connected: false
    property bool wifiEnabled: false
    property string wifiName: ""
    property int signalStrength: 0
    property var accessPoints: []
    // [{ name, type, device, active }]
    property var profiles: []

    property bool _connecting: false
    property string _connectSsid: ""
    property string _fallbackName: ""
    property var _profileBuf: []
    property string _activeProfile: ""

    signal connectSucceeded(string ssid)
    signal connectFailed(string ssid, string error)
    // Emitted when a connect failure looks like missing credentials; views
    // show the password prompt instead of a generic error.
    signal authRequired(string ssid)
    signal disconnectFinished()

    function toggleWifi() {
        var enable = !root.wifiEnabled
        toggleCmd.command = ["nmcli", "radio", "wifi", enable ? "on" : "off"]
        toggleCmd.run()
        root.wifiEnabled = enable
    }

    function rescan() {
        rescanCmd.run()
    }

    function connectToNetwork(ssid, password) {
        root._connecting = true
        root._connectSsid = ssid
        var cmd = ["nmcli", "dev", "wifi", "connect", ssid]
        if (password && password.length > 0)
            cmd.push("password", password)
        connectCmd.command = cmd
        connectCmd.run()
    }

    function disconnect() {
        if (root.wifiName && root.wifiName.length > 0)
            disconnectCmd.command = ["nmcli", "connection", "down", root.wifiName]
        else
            disconnectCmd.command = ["nmcli", "dev", "disconnect", "wifi"]
        disconnectCmd.run()
    }

    function forgetNetwork(ssid) {
        forgetCmd.command = ["nmcli", "connection", "delete", ssid]
        forgetCmd.run()
    }

    function setProfileUp(name) {
        profileActionCmd.command = ["nmcli", "connection", "up", name]
        profileActionCmd.run()
    }

    function setProfileDown(name) {
        profileActionCmd.command = ["nmcli", "connection", "down", name]
        profileActionCmd.run()
    }

    function refresh() {
        root.accessPoints = []
        radioCmd.run()
        listCmd.run()
        refreshProfiles()
    }

    function refreshProfiles() {
        profilesCmd.run()
    }

    function _quickRefresh() {
        radioCmd.run()
        listCmd.run()
    }

    // The AP list is the single source of truth; the fallback covers a
    // connected profile with no visible AP row (hidden SSID).
    function _syncActive() {
        var active = null
        for (var i = 0; i < root.accessPoints.length; i++)
            if (root.accessPoints[i].active) { active = root.accessPoints[i]; break }
        root.wifiName = active ? active.ssid : root._fallbackName
        root.connected = root.wifiName !== ""
        root.signalStrength = active ? active.signal : 0
    }

    function _looksLikeAuth(msg) {
        var m = String(msg).toLowerCase()
        return m.indexOf("secret") !== -1 || m.indexOf("password") !== -1 || m.indexOf("key-mgmt") !== -1
    }

    // ── nmcli adapter ──────────────────────────────────────────────────────
    // One wifi-list pass feeds both the AP rows and the active summary.
    readonly property string listScript: "saved=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | sed 's/\\\\:/<N>/g' | grep ':802-11-wireless$' | sed 's/:802-11-wireless$//' | sed 's/<N>/:/g')\n" +
        "active_found=0\n" +
        "while IFS=: read -r active signal ssid security; do\n" +
        "  [ -z \"$ssid\" ] && continue\n" +
        "  [ \"$ssid\" = \"--\" ] && continue\n" +
        "  ssid=$(echo \"$ssid\" | sed 's/<ESC>/:/g')\n" +
        "  is_saved=no; echo \"$saved\" | grep -qxF \"$ssid\" && is_saved=yes\n" +
        "  case \"$active\" in yes|\\*) active_found=1;; esac\n" +
        "  printf 'AP||%s||%s||%s||%s||%s\\n' \"$active\" \"$signal\" \"$ssid\" \"$security\" \"$is_saved\"\n" +
        "done < <(nmcli -t -f ACTIVE,SIGNAL,SSID,SECURITY dev wifi list 2>/dev/null | sed 's/\\\\:/<ESC>/g')\n" +
        "if [ \"$active_found\" = \"0\" ]; then\n" +
        "  name=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -E ':(wireless|802-11-wireless)$' | head -1 | cut -d: -f1)\n" +
        "  printf 'FALLBACK||%s\\n' \"${name:-}\"\n" +
        "fi"

    readonly property string profilesScript:
        "nmcli -t -f NAME,TYPE,DEVICE connection show 2>/dev/null | while IFS=: read -r name type device; do " +
        "  case \"$type\" in 802-3-ethernet|vpn|wireguard|tun) printf 'PROFILE\\t%s\\t%s\\t%s\\n' \"$name\" \"$type\" \"$device\";; esac; " +
        "done; " +
        "nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | while IFS=: read -r name type device; do " +
        "  case \"$type\" in 802-3-ethernet|vpn|wireguard|tun) printf 'ACTIVE\\t%s\\n' \"$name\";; esac; " +
        "done"

    Cmd {
        id: radioCmd
        command: ["nmcli", "-c", "no", "radio", "wifi"]
        autorun: false
        onLine: function(line) { root.wifiEnabled = line.trim() === "enabled" }
    }

    Cmd {
        id: listCmd
        command: ["bash", "-c", root.listScript]
        autorun: false
        onLine: function(line) {
            if (line.indexOf("FALLBACK||") === 0) {
                root._fallbackName = line.slice(10).trim()
                return
            }
            if (line.indexOf("AP||") !== 0) return
            var parts = line.split("||")
            if (parts.length < 6) return
            var active = parts[1] === "*" || parts[1] === "yes"
            var signal = parseInt(parts[2]) || 0
            var ssid = parts[3].trim()
            var security = parts[4].trim()
            var saved = parts[5].trim() === "yes"
            if (ssid === "") return

            var aps = root.accessPoints.slice()
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
        onDone: root._syncActive()
    }

    Cmd {
        id: profilesCmd
        command: ["bash", "-c", root.profilesScript]
        autorun: false
        onLine: function(line) {
            if (line.indexOf("ACTIVE\t") === 0) {
                root._activeProfile = line.slice(7).trim()
                return
            }
            if (line.indexOf("PROFILE\t") !== 0) return
            var p = line.slice(8).split("\t")
            if (p.length >= 3 && p[0] !== "")
                root._profileBuf.push({ name: p[0], type: p[1], device: p[2], active: false })
        }
        onDone: {
            var out = []
            for (var i = 0; i < root._profileBuf.length; i++) {
                var e = root._profileBuf[i]
                out.push({ name: e.name, type: e.type, device: e.device, active: e.name === root._activeProfile })
            }
            root.profiles = out
            root._profileBuf = []
            root._activeProfile = ""
        }
    }

    Cmd {
        id: toggleCmd
        autorun: false
        onDone: function(code) { if (code === 0) refreshDebounce.restart() }
    }

    Cmd {
        id: connectCmd
        autorun: false
        property string stderrBuf: ""
        onStderrLine: function(line) {
            var t = line.trim()
            if (t.length > 0) connectCmd.stderrBuf += t + "\n"
        }
        onDone: function(code) {
            root._connecting = false
            if (code === 0) {
                root.connectSucceeded(root._connectSsid)
                refreshDebounce.restart()
            } else {
                var err = connectCmd.stderrBuf.trim() || "Connection failed"
                if (root._looksLikeAuth(err)) root.authRequired(root._connectSsid)
                root.connectFailed(root._connectSsid, err)
            }
            connectCmd.stderrBuf = ""
        }
    }

    Cmd {
        id: disconnectCmd
        autorun: false
        onDone: function(code) {
            if (code === 0) {
                root.connected = false
                root.wifiName = ""
                root.signalStrength = 0
                root.disconnectFinished()
                refreshDebounce.restart()
            }
        }
    }

    Cmd {
        id: forgetCmd
        autorun: false
        onDone: function(code) { if (code === 0) refreshDebounce.restart() }
    }

    Cmd {
        id: rescanCmd
        command: ["nmcli", "dev", "wifi", "rescan"]
        autorun: false
        onDone: function(code) { if (code === 0) rescanRelistTimer.restart() }
    }

    Cmd {
        id: monitorCmd
        command: ["nmcli", "monitor"]
        onLine: function(line) { refreshTimer.restart() }
        onDone: monitorRestartTimer.start()
    }

    Cmd {
        id: profileActionCmd
        autorun: false
        onDone: profilesCmd.run()
    }

    // Qt.callLater ignores its second arg (runs next tick), so replace the
    // old fn,ms pattern with one-shot debounce timers.
    Timer {
        id: refreshDebounce
        interval: 500
        onTriggered: root.refresh()
    }
    Timer {
        id: rescanRelistTimer
        interval: 2000
        onTriggered: {
            root.accessPoints = []
            listCmd.run()
        }
    }
    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: root._quickRefresh()
    }
    Timer {
        id: monitorRestartTimer
        interval: 2000
        onTriggered: monitorCmd.run()
    }
    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
