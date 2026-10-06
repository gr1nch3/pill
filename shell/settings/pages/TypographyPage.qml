import QtQuick

import "../../services"
import "../../components"
import "../controls"

SettingsPage {
    id: root

    actions: [
        {
            label: "Reset Scale",
            icon: "󰑓",
            onTrigger: function () {
                Config.set("fontScale", 1.0);
            }
        }
    ]

    SettingRow {
        icon: "󰎆"
        title: "Font Family"
        subtitle: "UI text font — blank uses the system font"
        SettingEdit {
            value: Config.fontFamily
            placeholder: "(system)"
            onAccepted: function (text) {
                Config.set("fontFamily", text);
            }
        }
    }

    SettingRow {
        icon: "󰋜"
        title: "Icon Font"
        subtitle: "Font used for glyph icons"
        SettingEdit {
            value: Config.iconFontFamily
            placeholder: "(none)"
            onAccepted: function (text) {
                Config.set("iconFontFamily", text);
            }
        }
    }

    SettingRow {
        icon: "󰁃"
        title: "Font Scale"
        subtitle: "Scales every label in the shell"
        SettingStepper {
            value: Config.fontScale
            from: 0.5
            to: 2.0
            step: 0.1
            format: function (v) {
                return v.toFixed(1) + "x";
            }
            onValueEdited: function (v) {
                Config.set("fontScale", v);
            }
        }
    }

    SettingSection {
        icon: "󰎆"
        label: "PREVIEW"
        description: "Every size the shell renders, in the active face."
    }

    Item {
        id: specimenHero
        width: parent.width
        height: 176
        property real pop: 0
        scale: 1 + pop * 0.02

        Connections {
            target: Config
            function onFontScaleChanged() {
                popAnim.restart();
            }
        }

        SequentialAnimation {
            id: popAnim
            NumberAnimation {
                target: specimenHero
                property: "pop"
                to: 1
                duration: 90
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: specimenHero
                property: "pop"
                to: 0
                duration: 320
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.shape.radius.card
            color: Theme.surface
            border.width: Theme.shape.border.width
            border.color: Theme.border
            clip: true

            // editorial left rule
            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: 3
                color: Theme.accent
                opacity: 0.85
            }

            Column {
                id: aaCol
                anchors {
                    left: parent.left
                    leftMargin: 20
                    top: parent.top
                    topMargin: 16
                }
                spacing: 2
                Text {
                    text: "Aa"
                    color: Theme.text
                    font.family: Theme.font.family
                    font.pixelSize: 46
                    font.weight: 800
                }
                Text {
                    text: "Ag 0123"
                    color: Theme.subtext
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.size.caption
                }
            }

            Column {
                anchors {
                    left: aaCol.right
                    leftMargin: 18
                    right: parent.right
                    rightMargin: 16
                    top: parent.top
                    topMargin: 16
                }
                spacing: 6

                Repeater {
                    model: [
                        {
                            name: "HEADING",
                            size: Theme.font.size.large,
                            weight: 700,
                            sample: "Pill settings"
                        },
                        {
                            name: "BODY",
                            size: Theme.font.size.normal,
                            weight: 400,
                            sample: "The quick brown fox jumps over the lazy dog"
                        },
                        {
                            name: "CAPTION",
                            size: Theme.font.size.caption,
                            weight: 500,
                            sample: "secondary detail and meta"
                        }
                    ]

                    delegate: Column {
                        required property var modelData
                        width: parent.width
                        spacing: 2

                        Row {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: modelData.name
                                color: Theme.subtext
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.size.caption
                                font.weight: 700
                                font.letterSpacing: 0.8
                                width: 62
                            }

                            Text {
                                width: parent.width - 70
                                elide: Text.ElideRight
                                text: modelData.sample
                                color: Theme.text
                                font.family: Theme.font.family
                                font.pixelSize: modelData.size
                                font.weight: modelData.weight
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.border
                            opacity: 0.4
                        }
                    }
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: "mono · 0123456789 · {} [] <> · 󰍹 󰕾 󰂚"
                    color: Theme.subtext
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.size.caption
                }
            }

            Row {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 16
                }
                anchors.leftMargin: 20

                Text {
                    text: (Config.fontFamily !== "" ? Config.fontFamily : "system font") + " · icons " + (Config.iconFontFamily !== "" ? Config.iconFontFamily : "default")
                    color: Theme.subtext
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.size.caption
                    elide: Text.ElideRight
                    width: parent.width - scaleText.width - 8
                }

                Text {
                    id: scaleText
                    text: Number(Config.fontScale).toFixed(1) + "×"
                    color: Theme.accent
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.size.caption
                    font.weight: 700
                }
            }
        }
    }
}
