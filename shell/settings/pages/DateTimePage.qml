import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [{ label: "Refresh", icon: "󰑓", onTrigger: root.refresh }]

    property string zoneFilter: ""
    property var allZones: []

    readonly property var filteredZones: {
        var q = zoneFilter.trim().toLowerCase()
        var out = []
        for (var i = 0; i < allZones.length; i++) {
            if (q === "" || allZones[i].toLowerCase().indexOf(q) !== -1) out.push(allZones[i])
            if (out.length >= 40) break
        }
        return out
    }

    function openZonePicker() {
        root.zoneFilter = ""
        if (root.allZones.length === 0) zonesProc.running = true
        tzDialog.open()
    }

    function refresh() { DateTime.refresh() }

    SettingRow {
        icon: "󰅐"
        title: "Timezone"
        subtitle: DateTime.timezone !== "" ? DateTime.timezone : "Unknown"
        SettingAction {
            label: "Change"
            onClicked: root.openZonePicker()
        }
    }

    SettingRow {
        icon: "󰖟"
        title: "Network Time (NTP)"
        subtitle: "Keep the clock in sync with internet time servers"
        SettingToggle {
            checked: DateTime.ntp
            onToggled: DateTime.setNtp(!DateTime.ntp)
        }
    }

    SettingSection { icon: "󰅐"; label: "CLOCK" }

    SettingRow {
        icon: "󰅐"
        title: "Clock Format"
        subtitle: "How the shell clock displays time"
        keywords: "12h 24h am pm time"
        SettingChips {
            options: [{ value: "24", label: "24-hour" }, { value: "12", label: "12-hour" }]
            currentValue: Config.clockFormat
            onValueSelected: function(v) {
                Config.set("clockFormat", v)
                flick.contentY = 0
            }
        }
    }

    SettingNote { tone: "danger"; text: DateTime.lastError }

    // The zone catalogue is long and only needed while picking: a dialog keeps
    // the page from growing a 40-row inline list.
    SettingDialog {
        id: tzDialog
        title: "Timezone"
        description: "Search the system's zone list and pick a city."

        SettingEdit {
            id: tzFilter
            width: parent.width
            live: true
            value: root.zoneFilter
            placeholder: "City or region"
            onTextEdited: function(text) { root.zoneFilter = text }
        }

        ListView {
            id: zoneList
            width: parent.width
            height: Math.min(contentHeight, 260)
            clip: true
            model: root.filteredZones
            spacing: 2

            delegate: Rectangle {
                id: zoneRow
                required property string modelData
                width: zoneList.width
                height: 30
                radius: Theme.shape.radius.hairline
                color: zoneMouse.containsMouse || zoneRow.modelData === DateTime.timezone
                    ? Theme.surfaceHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                Text {
                    anchors {
                        left: parent.left; leftMargin: 10
                        right: zoneCheck.left; rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    text: zoneRow.modelData
                    color: Theme.text
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    elide: Text.ElideRight
                }

                Text {
                    id: zoneCheck
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    visible: zoneRow.modelData === DateTime.timezone
                    text: "✓"
                    color: Theme.accent
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    font.weight: 800
                }

                MouseArea {
                    id: zoneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        DateTime.setTimezone(zoneRow.modelData)
                        tzDialog.close()
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.allZones.length === 0 || root.filteredZones.length === 0
            text: root.allZones.length === 0 ? "Loading timezones…" : "No timezone matches that search."
            color: Theme.subtext
            font.pixelSize: Theme.font.size.caption
            font.family: Theme.font.family
        }

        onOpened: tzFilter.focusInput()
    }

    Process {
        id: zonesProc
        command: ["timedatectl", "list-timezones"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var z = line.trim()
                if (z === "") return
                var next = root.allZones.slice()
                next.push(z)
                root.allZones = next
            }
        }
    }
}
