import QtQuick

import "../../services"
import "../../components"
import "../controls"

SettingsPage {
    id: root

    SettingSection { icon: "󰕾"; label: "OUTPUT" }

    Repeater {
        model: Audio.sinks

        SettingRow {
            id: sinkRow
            required property var modelData
            icon: sinkRow.modelData.muted ? "󰝟" : "󰕾"
            title: sinkRow.modelData.label
            subtitle: (sinkRow.modelData.isDefault ? "Active • " : "")
                + sinkRow.modelData.volume + "%"
                + (sinkRow.modelData.muted ? " • muted" : "")

            Slider {
                width: 220
                value: sinkRow.modelData.volume
                fillColor: Theme.accent
                icon: sinkRow.modelData.muted ? "󰝟" : "󰕾"
                onValueChangedByUser: function(pct) { Audio.setVolume(sinkRow.modelData.id, pct) }
                onIconClicked: Audio.toggleMute(sinkRow.modelData.id)
            }

            SettingAction {
                visible: !sinkRow.modelData.isDefault
                label: "Use"
                accent: true
                onClicked: Audio.setDefaultSink(sinkRow.modelData.id)
            }
        }
    }

    Text {
        visible: Audio.sinks.length === 0
        width: parent.width
        text: "No output devices found"
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
    }

    SettingSection { icon: "󰍬"; label: "INPUT" }

    Repeater {
        model: Audio.sources

        SettingRow {
            id: sourceRow
            required property var modelData
            icon: sourceRow.modelData.muted ? "󰍭" : "󰍬"
            title: sourceRow.modelData.label
            subtitle: (sourceRow.modelData.isDefault ? "Active • " : "")
                + sourceRow.modelData.volume + "%"
                + (sourceRow.modelData.muted ? " • muted" : "")

            Slider {
                width: 220
                value: sourceRow.modelData.volume
                fillColor: Theme.accentAlt
                icon: sourceRow.modelData.muted ? "󰍭" : "󰍬"
                onValueChangedByUser: function(pct) { Audio.setVolume(sourceRow.modelData.id, pct) }
                onIconClicked: Audio.toggleMute(sourceRow.modelData.id)
            }

            SettingAction {
                visible: !sourceRow.modelData.isDefault
                label: "Use"
                accent: true
                onClicked: Audio.setDefaultSource(sourceRow.modelData.id)
            }
        }
    }

    Text {
        visible: Audio.sources.length === 0
        width: parent.width
        text: "No input devices found"
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
    }
}
