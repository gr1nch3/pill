pragma Singleton
// One owner for power profile and the idle daemon (hypridle/swayidle pause).
// Polling is gated by `active` (bound to bar visibility in shell.qml).
import QtQuick

import "../utils"

Item {
    id: root

    property string profile: "balanced"
    property bool idleEnabled: true
    property bool active: true
    property bool _setting: false

    function setProfile(name) {
        root._setting = true
        root.profile = name
        setCmd.command = ["powerprofilesctl", "set", name]
        setCmd.run()
    }

    function toggleIdle() {
        root._setting = true
        root.idleEnabled = !root.idleEnabled
        var sig = root.idleEnabled ? "-CONT" : "-STOP"
        idleCmd.command = ["sh", "-c", "pkill " + sig + " -x hypridle; pkill " + sig + " -x swayidle; exit 0"]
        idleCmd.run()
    }

    function refresh() {
        statusCmd.run()
    }

    Cmd {
        id: statusCmd
        command: ["bash", "-c",
            "echo PP:$(powerprofilesctl get 2>/dev/null || echo balanced); " +
            "echo IDLE:$(ps -o stat= -C hypridle,swayidle 2>/dev/null | grep -q T && echo off || echo on)"]
        interval: 3000
        active: root.active
        onLine: function(line) {
            var i = line.indexOf(":")
            if (i < 0) return
            var key = line.slice(0, i)
            var val = line.slice(i + 1)
            if (key === "PP") { if (!root._setting) root.profile = val }
            else if (key === "IDLE") { if (!root._setting) root.idleEnabled = val === "on" }
        }
    }

    Cmd {
        id: setCmd
        autorun: false
        onDone: {
            root._setting = false
            statusCmd.run()
        }
    }

    Cmd {
        id: idleCmd
        autorun: false
        onDone: {
            root._setting = false
            statusCmd.run()
        }
    }

    Component.onCompleted: root.refresh()
}
