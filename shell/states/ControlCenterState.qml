import QtQuick
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

    opacity: IslandState.state === "controlcenter" ? 1 : 0
    visible: opacity > 0
    focus: visible
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Keys.onEscapePressed: IslandState.closeToIdle()

    onVisibleChanged: {
        if (visible) statusProc.running = true
    }

    // ── Local status polling ────────────────────────────────────────────────
    property string audioDevice: ""
    property string inputDevice: ""
    property string powerProfile: "balanced"
    // ponytail: one pending flag for both setters — a 400ms recheck follows.
    property bool _setting: false
    property bool idleEnabled: true
    readonly property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool btBlocked: (Bluetooth.defaultAdapter?.state ?? 0) === 4
    property bool _btPendingUnblock: false

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

    Process {
        id: statusProc
        command: ["bash", "-c",
            "echo ADEV:$(def=$(pactl get-default-sink); pactl list sinks | grep -A20 \"Name: $def\" | grep 'Description:' | head -1 | cut -d: -f2- | xargs); " +
            "echo IDEV:$(pactl get-default-source 2>/dev/null | head -1 | xargs); " +
            "echo PP:$(powerprofilesctl get 2>/dev/null || echo balanced); " +
            "echo IDLE:$(ps -o stat= -C hypridle,swayidle 2>/dev/null | grep -q T && echo off || echo on)"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.trim().split(":")
                var key = parts[0]
                var val = parts.slice(1).join(":")
                if (key === "ADEV") root.audioDevice = val
                else if (key === "IDEV") root.inputDevice = val
                else if (key === "PP") {
                    if (!root._setting)
                        root.powerProfile = val
                }
                else if (key === "IDLE") {
                    if (!root._setting)
                        root.idleEnabled = val === "on"
                }
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; onTriggered: statusProc.running = true }

    Process {
        id: ppSetProc
        command: []; running: false
        onExited: {
            root._setting = false
            recheckPpTimer.restart()
        }
    }

    Timer {
        id: recheckPpTimer
        interval: 400
        onTriggered: statusProc.running = true
    }

    // ── Sleep (pause the idle daemon, e.g. hypridle/swayidle; owned by the
    // user compositor config, not by bubbles) ──────────────────────────
    function toggleIdle() {
        root._setting = true
        root.idleEnabled = !root.idleEnabled
        var sig = root.idleEnabled ? "-CONT" : "-STOP"
        idleProc.command = ["sh", "-c", "pkill " + sig + " -x hypridle; pkill " + sig + " -x swayidle; exit 0"]
        idleProc.running = true
    }

    Process {
        id: idleProc
        command: []; running: false
        onExited: {
            root._setting = false
            recheckPpTimer.restart()
        }
    }

    // ── Layout ─────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: 10

        // ── Title bar ────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 32

            // Eyes glance at the toggle rows to their right (PRD §6.4).
            // ponytail: A/B the slant sign before locking personality in.
            Eye {
                id: ccEyes
                eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                slant: 4
                moods: Theme.eyeMoods
                // Low battery reads as amber alert (PRD §6.3).
                mood: (Battery.percent <= 20 && Battery.status !== "Charging") ? "alert" : "active"
            }

            Text {
                id: titleText
                text: "Control Center"
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: ccEyes.right
                anchors.leftMargin: 10
            }

            Rectangle {
                id: settingsBtn
                width: 32; height: 32; radius: 10
                color: settingsHover.containsMouse ? Theme.surfaceHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: powerBtn.left //; anchors.rightMargin: 3
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.xlarge
                    font.family: Theme.font.mono
                }

                MouseArea {
                    id: settingsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: IslandState.open("settings")
                }
            }

            Rectangle {
                id: powerBtn
                width: 32; height: 32; radius: 10
                color: powerHover.containsMouse ? Theme.danger : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    color: powerHover.containsMouse ? Theme.background : Theme.subtext
                    font.pixelSize: Theme.font.size.xlarge
                    font.family: Theme.font.mono
                }

                MouseArea {
                    id: powerHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: IslandState.open("session")
                }
            }

        }

        // ── Large toggle tiles ───────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 5

            ToggleTile {
                width: (parent.width - 20) / 3
                icon: Network.wifiEnabled ? "󰤨" : "󰤭"
                title: "Wi-Fi"
                subtitle: Network.wifiEnabled ? (Network.wifiName || "On") : "Off"
                btnActive: Network.wifiEnabled
                onIconClicked: Network.toggleWifi()
                onClicked: {
                    IslandState.deviceSelectType = "wifi"
                    IslandState.open("connectivity")
                }
            }

            ToggleTile {
                width: (2 * parent.width - 10) / 3
                icon: Volume.muted ? "󰝟" : "󰕾"
                title: "Audio"
                subtitle: root.audioDevice || "Output"
                btnActive: !Volume.muted
                onIconClicked: Volume.toggleMute()
                onClicked: {
                    IslandState.deviceSelectType = "audio"
                    IslandState.open("audiodevice")
                }
            }
        }

        // ── Power profile + Bluetooth  ────────────────────────────────────
        Row {
            width: parent.width
            spacing: 5

            Rectangle {
              width: (parent.width - 10) / 2
                height: 64
                radius: 10
                color: Theme.background

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: [
                            { key: "power-saver", icon: Icons.powerSaver },
                            { key: "balanced", icon: Icons.powerBalanced },
                            { key: "performance", icon: Icons.powerPerf }
                        ]
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            property bool isActive: root.powerProfile === modelData.key

                            width: (parent.parent.width - 25) / 3; height: 50; radius: 8
                            color: isActive ? Theme.accent : (chipMouse.containsMouse ? Theme.surfaceHover : "transparent")
                            border.width: isActive ? 0 : 1
                            border.color: Theme.border
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: isActive ? Theme.background : Theme.text
                                font.pixelSize: Theme.font.size.xlarge
                                font.family: Theme.font.mono
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root._setting = true
                                    root.powerProfile = modelData.key
                                    ppSetProc.command = ["powerprofilesctl", "set", modelData.key]
                                    ppSetProc.running = true
                                }
                            }
                        }
                    }
                }
            }

            ToggleTile {
                id: btTile
                width: (parent.width - 20) / 2
                height: 64
                icon: root.btEnabled ? "󰂯" : (root.btBlocked ? "󰂰" : "󰂲")
                title: "BT"
                subtitle: root.btBlocked ? "Blocked" : (root.btEnabled ? "On" : "Off")
                btnActive: root.btEnabled
                onIconClicked: {
                    var adapter = Bluetooth.defaultAdapter
                    if (!adapter) return
                    if (adapter.state === 4 /* Blocked */) {
                        root._btPendingUnblock = true
                        btRfkillProc.running = true
                    } else {
                        adapter.enabled = !adapter.enabled
                    }
                }
                onClicked: {
                    IslandState.deviceSelectType = "bluetooth"
                    IslandState.open("connectivity")
                }
            }

        }

        // ── Focus + Sleep + Mic tiles ────────────────────────────────
        Row {
            width: parent.width
            spacing: 10

            ToggleTile {
                width: (parent.width - 50) / 6
                icon: NotificationManager.doNotDisturb ? Icons.dndOn : Icons.dndOff
                title: "Focus"
                subtitle: NotificationManager.doNotDisturb ? "On" : "Off"
                tileActive: NotificationManager.doNotDisturb
                iconButton: false
                onIconClicked: NotificationManager.doNotDisturb = !NotificationManager.doNotDisturb
                onClicked: NotificationManager.doNotDisturb = !NotificationManager.doNotDisturb
            }

            ToggleTile {
                width: (parent.width - 50) / 6
                icon: Icons.suspend
                title: "Sleep"
                subtitle: root.idleEnabled ? "On" : "Off"
                tileActive: root.idleEnabled
                iconButton: false
                onIconClicked: root.toggleIdle()
                onClicked: root.toggleIdle()
            }

            ToggleTile {
                width: (2 * parent.width - 10) / 3
                icon: Volume.micMuted ? Icons.micOff : Icons.micOn
                title: "Mic"
                subtitle: Volume.micMuted ? "Muted" : (root.inputDevice || "Input")
                btnActive: !Volume.micMuted
                onIconClicked: Volume.toggleMic()
                onClicked: {
                    IslandState.deviceSelectType = "mic"
                    IslandState.open("audiodevice")
                }
            }
        }

        // ── Volume slider ────────────────────────────────────────────────
        Slider {
            width: parent.width
            value: Volume.percent
            fillColor: Theme.accent
            icon: Volume.percent === 0 || Volume.muted ? "󰝟" : "󰕾"
            onValueChangedByUser: function(pct) { Volume.setPercent(pct) }
            onIconClicked: Volume.toggleMute()
        }

        // ── Brightness slider ────────────────────────────────────────────
        Slider {
            width: parent.width
            value: Brightness.percent
            fillColor: Theme.accentAlt
            icon: "󰃠"
            onValueChangedByUser: function(pct) { Brightness.setPercent(pct) }
        }

        // ── System Monitor ──────────────────────────────────────────────
        Item {
            width: parent.width
            height: 68

            Row {
                anchors.fill: parent
                spacing: 6

                StatCard {
                    cardIcon: "󰻠"
                    iconColor: Theme.accentAlt
                    cardValue: SystemStats.cpuPercent
                    accentColor: Theme.accentAlt
                }

                StatCard {
                    cardIcon: "󰍛"
                    iconColor: Theme.accent
                    cardValue: SystemStats.ramPercent
                    accentColor: Theme.accent
                }

                StatCard {
                    cardIcon: "󰋊"
                    iconColor: Theme.subtext
                    cardValue: SystemStats.diskPercent
                    accentColor: Theme.subtext
                }
            }
        }

        // ── Notifications section ────────────────────────────────────────
        Item {
            id: notifSection
            width: parent.width
            height: parent.height - notifSection.y

            Row {
                id: notifHeader
                anchors.top: parent.top
                width: parent.width
                Text {
                    text: "Notifications"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.family
                    font.bold: true
                    width: parent.width - 50
                }
                Text {
                    text: "Clear all"
                    color: clearAllCCHover.containsMouse ? Theme.danger : Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    visible: NotificationManager.notificationList.length > 0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea { id: clearAllCCHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: NotificationManager.clear() }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: NotificationManager.notificationList.length === 0
                text: "No notifications"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
                width: parent.width; horizontalAlignment: Text.AlignHCenter
            }

            ListView {
                anchors.top: notifHeader.bottom
                anchors.topMargin: 8
                anchors.bottom: parent.bottom
                width: parent.width
                visible: NotificationManager.notificationList.length > 0
                clip: true
                spacing: 6
                model: NotificationManager.notificationList

                delegate: Rectangle {
                    width: ListView.view.width
                    height: Math.max(48, notifCCCol.implicitHeight + 16)
                    radius: 12
                    color: modelData.urgency === 2 ? Theme.dangerBg : Theme.background
                    required property var modelData
                    required property int index
                    property int notifIndex: index

                    Row {
                        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 10; rightMargin: 28 }
                        spacing: 8

                        NotifIcon {
                            width: 28; height: 28; radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            appIcon: modelData.appIcon || ""
                            appName: modelData.appName || ""
                            urgency: modelData.urgency || 0
                        }

                        Column {
                            id: notifCCCol
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 36
                            spacing: 2

                            Text {
                                text: modelData.appName || "notification"
                                color: Theme.subtext
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                width: parent.width; elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.summary || ""
                                color: Theme.text
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.family
                                font.weight: 500
                                width: parent.width; elide: Text.ElideRight
                            }
                            Text {
                                visible: modelData.body !== ""
                                text: modelData.body
                                color: Theme.subtext
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.family
                                width: parent.width; wrapMode: Text.WordWrap
                                maximumLineCount: 2; elide: Text.ElideRight
                            }
                        }
                    }

                    Text {
                        text: Icons.close; font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.mono
                        color: dismissCCHover.containsMouse ? Theme.danger : Theme.subtext
                        anchors { right: parent.right; top: parent.top; margins: 8 }
                        Behavior on color { ColorAnimation { duration: 100 } }
                        MouseArea {
                            id: dismissCCHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationManager.remove(notifIndex)
                        }
                    }
                }
            }
        }
    }
}
