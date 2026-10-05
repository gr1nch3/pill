import QtQuick

import "../services"
import "../components"
import "../utils"
import "../eyes"

StatePane {
    id: root
    stateName: "idle"
    radiusMode: "pill"
    preferredWidth: root.expanded ? (Playerctl.musicPlaying ? 520 : 360) : (Playerctl.musicPlaying ? 140 : (EyeReactions.active && Config.eyesEnabled ? 118 : 90))
    preferredHeight: IslandState.idleExpanded ? 64 : 34

    anchors.fill: parent

    property bool ready: false
    property bool expanded: ready && IslandState.idleExpanded

    // ── Collapsed view: cava + time + ram arc ──────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 3
        opacity: !root.expanded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.motion.panel
                easing.type: Easing.OutCubic
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 6

            // Media indicator: the face comes alive when a track plays (§6.4),
            // and pops in for a moment on any startle (notification, charger,
            // recording) so reactions are visible at rest too.
            EyeFace {
                anchors.verticalCenter: parent.verticalCenter
                eyeWidth: 13
                eyeHeight: 10
                eyeSpacing: 5
                visible: (Playerctl.musicPlaying || EyeReactions.active) && Config.eyesEnabled
                baseMood: "active"
                beat: Cava.level
            }

            CompactClock {
                anchors.verticalCenter: parent.verticalCenter
                fontSize: Theme.font.size.large
                fontWeight: 600
                active: IslandState.shellActive
            }

            ArcCanvas {
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter
                value: SystemStats.ramPercent / 100
                arcColor: Theme.accent
                trackColor: Theme.background
                lineWidth: 2.5
                visible: !Capture.recording
            }

            Rectangle {
                width: 10
                height: 10
                radius: 5
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.danger
                visible: Capture.recording
                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: Theme.danger
                    opacity: 0.4
                    SequentialAnimation on opacity {
                        running: Capture.recording
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.1
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 0.4
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Capture.view = "recording";
                        IslandState.state = "capture";
                    }
                }
            }
        }
    }

    // ── Expanded view: media + time/date + wifi/battery ────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 14
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.motion.panel
                easing.type: Easing.OutCubic
            }
        }

        Row {
            anchors.fill: parent
            spacing: 0

            // ── Media (left) ─────────────────────────────────────────────
            Item {
                width: Playerctl.musicPlaying ? parent.width * 0.36 : 0
                height: parent.height
                visible: Playerctl.musicPlaying

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: IslandState.open("mediaplayer")
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: parent.width
                    spacing: 8

                    MediaArt {
                        width: 36
                        height: 36
                        radius: Theme.shape.radius.control
                        source: Playerctl.musicArtResolved
                        placeholderSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: parent.width - 44

                        Row {
                            width: parent.width
                            spacing: 6

                            CavaBars {
                                width: 16
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Playerctl.musicPlaying
                                bars: Cava.bars
                            }

                            Text {
                                text: Playerctl.musicTitle
                                color: Theme.text
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.family
                                font.weight: 600
                                elide: Text.ElideRight
                                width: parent.width - 22
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: Playerctl.musicArtist
                            color: Theme.subtext
                            font.pixelSize: Theme.font.size.caption
                            font.family: Theme.font.family
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }
            }

            // ── Clock + Date ─────────────────────────────────────────────
            Item {
                width: Playerctl.musicPlaying ? parent.width * 0.34 : parent.width * 0.6
                height: parent.height

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: Playerctl.musicPlaying ? parent.horizontalCenter : undefined
                    anchors.left: Playerctl.musicPlaying ? undefined : parent.left
                    spacing: 10

                    EyeFace {
                        anchors.verticalCenter: parent.verticalCenter
                        eyeWidth: 16
                        eyeHeight: 12
                        eyeSpacing: 7
                        visible: !Capture.recording && Config.eyesEnabled
                        baseMood: Playerctl.musicPlaying ? "active" : "idle"
                        beat: Cava.level
                    }

                    Column {
                        spacing: 1

                        CompactClock {
                            id: expClock
                            fontSize: Theme.font.size.xlarge
                            ampmFontSize: Theme.font.size.small
                            fontWeight: 700
                            ampmBottomMargin: 2
                            active: IslandState.shellActive
                        }

                        Text {
                            id: expDateText
                            anchors.horizontalCenter: expClock.horizontalCenter
                            width: expClock.width
                            horizontalAlignment: Text.AlignHCenter
                            color: Theme.subtext
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.family
                            text: expClock.dateText
                        }
                    }
                }
            }

            // ── Recording / WiFi + Battery (right) ──────────────────────
            Item {
                width: Playerctl.musicPlaying ? parent.width * 0.30 : parent.width * 0.40
                height: parent.height

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: IslandState.open("controlcenter")
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        visible: Capture.recording
                        width: recRow.width + 12
                        height: 28
                        radius: Theme.shape.radius.cardLarge
                        color: Theme.dangerBg
                        border.color: Theme.danger
                        border.width: Theme.shape.border.width
                        Row {
                            id: recRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Icons.recStop
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.mono
                                color: Theme.danger
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: Capture.elapsed
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                font.weight: 600
                                color: Theme.danger
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Capture.view = "recording";
                                IslandState.state = "capture";
                            }
                        }
                    }

                    Rectangle {
                        width: statusRow.width + 16
                        height: 28
                        radius: Theme.shape.radius.cardLarge
                        color: Theme.background
                        border.color: Theme.border
                        border.width: Theme.shape.border.width

                        Row {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: Network.connected ? Icons.networkOn : Icons.networkOff
                                font.pixelSize: Theme.font.size.large
                                font.family: Theme.font.mono
                                color: Network.connected ? Theme.accent : Theme.subtext
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                readonly property bool charging: Battery.status === "Charging"
                                readonly property color batColor: charging ? Theme.accent : (Battery.percent <= 20 ? Theme.danger : Theme.text)

                                width: 30
                                height: 14
                                radius: 4
                                color: "transparent"
                                border.color: batColor
                                border.width: Theme.shape.border.width
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: Math.max(2, parent.width * (Battery.percent / 100) - 2)
                                    height: parent.height - 2
                                    radius: Theme.shape.radius.hairline
                                    color: parent.batColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 1
                                    opacity: parent.charging ? 0.5 : 0.25
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: Battery.percent + "%"
                                    color: parent.batColor
                                    font.pixelSize: Theme.font.size.caption
                                    font.family: Theme.font.family
                                    font.weight: 600
                                }
                            }

                            Text {
                                visible: Battery.status === "Charging" || Battery.status === "Full"
                                text: Icons.batteryCharging
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.mono
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
