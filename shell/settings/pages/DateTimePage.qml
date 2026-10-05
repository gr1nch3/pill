import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    property string zoneFilter: ""
    property var allZones: []
    property bool zonePickerOpen: false

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
        zonePickerOpen = !zonePickerOpen
        if (zonePickerOpen && allZones.length === 0)
            zonesProc.running = true
    }

    function refresh() { DateTime.refresh() }

    SettingSection { icon: "󰅐"; label: "DATE & TIME" }

    SettingRow {
        icon: "󰅐"
        title: "Timezone"
        subtitle: DateTime.timezone !== "" ? DateTime.timezone : "Unknown"
        SettingAction {
            label: root.zonePickerOpen ? "Close" : "Change"
            onClicked: root.openZonePicker()
        }
    }

    SettingRow {
        visible: root.zonePickerOpen
        icon: "󰍉"
        title: "Find a City"
        subtitle: "Type to filter " + root.allZones.length + " timezones"
        SettingEdit {
            width: 240
            live: true
            value: root.zoneFilter
            placeholder: "City or region"
            onTextEdited: function(text) { root.zoneFilter = text }
            Component.onCompleted: focusInput()
        }
    }

    Repeater {
        model: root.zonePickerOpen ? root.filteredZones : []

        SettingRow {
            required property string modelData
            icon: "󰅐"
            title: modelData
            SettingAction {
                label: "Use"
                accent: modelData === DateTime.timezone
                onClicked: {
                    DateTime.setTimezone(modelData)
                    root.zonePickerOpen = false
                }
            }
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
