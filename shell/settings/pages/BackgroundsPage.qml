import QtQuick
import "../../components"
import "../../eyes"

import "../../services"
import "../../utils"
import "../controls"

SettingsPage {
    id: root

    property string greeterStatus: ""
    property string greeterStatusTone: "muted"

    // Changing any pattern setting flashes the preview so the repaint reads as
    // "this is what changed" instead of an unexplained redraw.
    readonly property string patternKey: Config.patternStyle + "/" + Config.patternDensity + "/" + Config.lockPattern + "/" + Config.lockPatternStyle + "/" + Config.lockPatternDensity + "/" + Config.lockWallpaper
    onPatternKeyChanged: flashAnim.restart()

    SettingSection {
        icon: "󰏘"
        label: "PANEL PATTERNS"
    }

    SettingRow {
        icon: "󰏘"
        title: "Pattern"
        subtitle: "Behind large panels: launcher, wallpaper, clipboard, settings, theme, control center, media"
        SettingChips {
            options: [
                {
                    value: "none",
                    label: "None"
                },
                {
                    value: "dots",
                    label: "Dots"
                },
                {
                    value: "grid",
                    label: "Grid"
                },
                {
                    value: "diagonal",
                    label: "Slant"
                },
                {
                    value: "cross",
                    label: "Cross"
                },
                {
                    value: "chevron",
                    label: "Chevron"
                },
                {
                    value: "noise",
                    label: "Noise"
                }
            ]
            currentValue: Config.patternStyle
            onValueSelected: function (v) {
                Config.set("patternStyle", v);
            }
        }
    }

    SettingRow {
        icon: "󰏘"
        title: "Density"
        subtitle: "Pattern pitch"
        SettingChips {
            options: [
                {
                    value: "sparse",
                    label: "Sparse"
                },
                {
                    value: "normal",
                    label: "Normal"
                },
                {
                    value: "dense",
                    label: "Dense"
                }
            ]
            currentValue: Config.patternDensity
            onValueSelected: function (v) {
                Config.set("patternDensity", v);
            }
        }
    }

    Item {
        id: previewHero
        width: parent.width
        height: 172

        // ── live preview: the pattern behind a panel, and on the lock screen ────
        Row {
            id: previewRow
            width: parent.width
            spacing: 8

            // desktop panels
            Rectangle {
                width: (parent.width - 8) / 2
                height: 172
                radius: Theme.shape.radius.card
                color: Theme.background
                border.width: Theme.shape.border.width
                border.color: Theme.border
                clip: true

                PatternBackground {
                    anchors.fill: parent
                    variant: Config.patternStyle
                    spacing: Theme.patternSpacing
                    strength: 0.11
                    color: Theme.accent
                    shape: "rounded"
                    radius: parent.radius
                }

                // mini island pill with the real face
                Rectangle {
                    id: mockPill
                    anchors {
                        top: parent.top
                        topMargin: 12
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: 86
                    height: 22
                    radius: height / 2
                    color: Theme.background
                    border.width: Theme.shape.border.width
                    border.color: Theme.border

                    EyeFace {
                        anchors.centerIn: parent
                        eyeWidth: 10
                        eyeHeight: 7
                        eyeSpacing: 5
                        baseMood: "active"
                    }
                }

                // a panel sitting on the pattern
                Rectangle {
                    id: mockPanel
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 16
                    width: parent.width * 0.76
                    height: 84
                    radius: Theme.shape.radius.row
                    color: Theme.surface
                    border.width: Theme.shape.border.width
                    border.color: Theme.border

                    Row {
                        anchors {
                            left: parent.left
                            top: parent.top
                            margins: 10
                        }
                        spacing: 5
                        Repeater {
                            model: [Theme.accent, Theme.accentAlt, Theme.subtext]
                            Rectangle {
                                required property color modelData
                                width: 6
                                height: 6
                                radius: 3
                                color: modelData
                                opacity: 0.8
                            }
                        }
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                            margins: 12
                        }
                        anchors.topMargin: 26
                        spacing: 7

                        Repeater {
                            model: [0.72, 0.5, 0.86, 0.4]
                            Rectangle {
                                required property real modelData
                                width: parent.width * modelData
                                height: 6
                                radius: 3
                                color: Theme.highlight
                            }
                        }
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 10
                    }
                    text: "PANELS"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.family
                    font.weight: 700
                    font.letterSpacing: 0.8
                }
            }

            // lock screen
            Rectangle {
                width: (parent.width - 8) / 2
                height: 172
                radius: Theme.shape.radius.card
                color: Theme.background
                border.width: Theme.shape.border.width
                border.color: Theme.border
                clip: true

                PatternBackground {
                    anchors.fill: parent
                    variant: !Config.lockPattern ? "none" : (Config.lockPatternStyle !== "" ? Config.lockPatternStyle : Config.patternStyle)
                    spacing: {
                        var d = Config.lockPatternDensity !== "" ? Config.lockPatternDensity : Config.patternDensity;
                        return d === "dense" ? 13 : (d === "sparse" ? 26 : 18);
                    }
                    strength: 0.16
                    color: Theme.accent
                    shape: "rounded"
                    radius: parent.radius
                }

                // lock wallpaper stand-in: a bounded still when enabled
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 52
                    color: Config.lockWallpaper ? Theme.surface : "transparent"
                    opacity: 0.9
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 7

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 40
                        radius: 20
                        color: Theme.background
                        border.width: Theme.shape.border.width
                        border.color: Config.lockPattern ? Theme.accent : Theme.border
                        Behavior on border.color {
                            ColorAnimation {
                                duration: Theme.motion.hover
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰌾"
                            color: Theme.accent
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.mono
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "12:34"
                        color: Theme.text
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.family
                        font.weight: 700
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 10
                    }
                    text: "LOCK"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.family
                    font.weight: 700
                    font.letterSpacing: 0.8
                }
            }
        }

        // repaint flash over both mocks
        Rectangle {
            id: previewFlash
            width: previewRow.width
            height: previewRow.height
            radius: Theme.shape.radius.card
            color: Theme.accent
            opacity: 0
            SequentialAnimation {
                id: flashAnim
                NumberAnimation {
                    target: previewFlash
                    property: "opacity"
                    to: 0.14
                    duration: 70
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: previewFlash
                    property: "opacity"
                    to: 0
                    duration: 520
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    SettingSection {
        icon: "󰋩"
        label: "LOCK & SIGN-IN"
    }

    SettingRow {
        icon: "󰋩"
        title: "Wallpaper"
        subtitle: "Show the lock wallpaper on the lock screen; gifs animate, videos show a still frame"
        SettingToggle {
            value: Config.lockWallpaper
            onValueEdited: function (v) {
                Config.set("lockWallpaper", v);
            }
        }
    }

    SettingRow {
        icon: "󰌾"
        title: "Lock wallpaper"
        subtitle: Config.lockWallpaperPath !== "" ? "Custom: " + Config.lockWallpaperPath.split("/").pop() : "Same as desktop — pick one in the Wallpaper panel and press L"
        SettingAction {
            visible: Config.lockWallpaperPath !== ""
            label: "Use desktop"
            onClicked: Config.set("lockWallpaperPath", "")
        }
    }

    SettingRow {
        icon: "󰏘"
        title: "Pattern overlay"
        subtitle: "Draw the pattern above the wallpaper on the lock screen"
        SettingToggle {
            value: Config.lockPattern
            onValueEdited: function (v) {
                Config.set("lockPattern", v);
            }
        }
    }

    SettingRow {
        icon: "󰏘"
        title: "Pattern style"
        subtitle: "Lock + sign-in overlay; Same follows the panel pattern"
        SettingChips {
            options: [
                {
                    value: "",
                    label: "Same"
                },
                {
                    value: "none",
                    label: "None"
                },
                {
                    value: "dots",
                    label: "Dots"
                },
                {
                    value: "grid",
                    label: "Grid"
                },
                {
                    value: "diagonal",
                    label: "Slant"
                },
                {
                    value: "cross",
                    label: "Cross"
                },
                {
                    value: "chevron",
                    label: "Chevron"
                },
                {
                    value: "noise",
                    label: "Noise"
                }
            ]
            currentValue: Config.lockPatternStyle
            onValueSelected: function (v) {
                Config.set("lockPatternStyle", v);
            }
        }
    }

    SettingRow {
        icon: "󰏘"
        title: "Pattern density"
        subtitle: "Lock + sign-in overlay pitch; Same follows the panel density"
        SettingChips {
            options: [
                {
                    value: "",
                    label: "Same"
                },
                {
                    value: "sparse",
                    label: "Sparse"
                },
                {
                    value: "normal",
                    label: "Normal"
                },
                {
                    value: "dense",
                    label: "Dense"
                }
            ]
            currentValue: Config.lockPatternDensity
            onValueSelected: function (v) {
                Config.set("lockPatternDensity", v);
            }
        }
    }

    SettingRow {
        icon: "󰒓"
        title: "Sign-in screen"
        subtitle: root.greeterStatus !== "" ? root.greeterStatus : "SDDM follows these settings; push the palette + wallpaper with polkit"
        subtitleTone: root.greeterStatusTone
        keywords: "sddm greeter login lock screen"
        SettingAction {
            label: "Sync Now"
            onClicked: {
                root.greeterStatus = "Syncing...";
                root.greeterStatusTone = "muted";
                greeterCmd.run();
            }
        }
    }

    SettingNote {
        text: "The sign-in screen can't read your home directory, so Pill copies the palette and one background file to /etc/xdg/pill: the animated gif when a gif is picked, otherwise a bounded still. `pill theme`/`update` do the same push."
    }

    Cmd {
        id: greeterCmd
        command: ["pill", "greeter"]
        autorun: false
        onDone: function (code) {
            root.greeterStatus = code === 0 ? "Palette + wallpaper pushed to the sign-in screen" : "Push failed (polkit cancelled or `pill` CLI missing)";
            root.greeterStatusTone = code === 0 ? "success" : "danger";
        }
    }
}
