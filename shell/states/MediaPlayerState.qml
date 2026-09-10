import QtQuick
import Quickshell.Io

import "../services"
import "../components"
import "../eyes"

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 16

    opacity: IslandState.state === "mediaplayer" ? 1 : 0
    visible: opacity > 0
    focus: visible
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Keys.onEscapePressed: IslandState.closeToIdle()

    Column {
        anchors.fill: parent
        spacing: 6

        Row {
            width: parent.width
            spacing: 8

            BackButton { anchors.verticalCenter: parent.verticalCenter; onClicked: IslandState.closeToIdle() }

            Text {
                text: "Now Playing"
                color: Theme.text
                font.pixelSize: Theme.font.size.normal
                font.family: Theme.font.family
                font.weight: 600
                anchors.verticalCenter: parent.verticalCenter
            }

            // Listening eyes: pulse with the track, dim when paused (§6.4).
            Eye {
                eyeWidth: 18; eyeHeight: 13; eyeSpacing: 7
                anchors.verticalCenter: parent.verticalCenter
                moods: Theme.eyeMoods
                mood: Playerctl.musicPlaying ? "active" : "idle"
                beat: Cava.level
            }
        }

        Item {
            width: parent.width
            height: parent.height - 28

            Row {
                anchors.centerIn: parent
                spacing: 12

                MediaArt {
                    width: 100; height: 100; radius: 12
                    source: Playerctl.musicArtResolved
                    placeholderSize: 28
                }

                Column {
                    width: Math.min(280, root.width - 112)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        text: Playerctl.musicTitle || "No track"
                        color: Theme.text
                        font.pixelSize: Theme.font.size.normal
                        font.family: Theme.font.family
                        font.weight: 700
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: Playerctl.musicArtist || "Unknown artist"
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Row {
                        width: parent.width
                        spacing: 6
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            width: 32; height: 32; radius: 8
                            color: shuffleBtn.containsMouse ? Theme.highlight : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: Theme.subtext
                                font.pixelSize: Theme.font.size.large
                                font.family: Theme.font.mono
                            }

                            MouseArea {
                                id: shuffleBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { shuffleProc.running = true }
                            }
                        }

                        Rectangle {
                            width: 36; height: 36; radius: 8
                            color: prevBtn.containsMouse ? Theme.highlight : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: "⏮"
                                color: Theme.text
                                font.pixelSize: Theme.font.size.xlarge
                            }

                            MouseArea {
                                id: prevBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Playerctl.previous()
                            }
                        }

                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: playBtn.containsMouse ? Theme.accent : Qt.lighter(Theme.accent, 0.8)
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: Playerctl.musicPlaying ? "⏸" : "▶"
                                color: Theme.background
                                font.pixelSize: Theme.font.size.xlarge
                                anchors.verticalCenterOffset: 1
                            }

                            MouseArea {
                                id: playBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Playerctl.playPause()
                            }
                        }

                        Rectangle {
                            width: 36; height: 36; radius: 8
                            color: nextBtn.containsMouse ? Theme.highlight : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: "⏭"
                                color: Theme.text
                                font.pixelSize: Theme.font.size.xlarge
                            }

                            MouseArea {
                                id: nextBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Playerctl.next()
                            }
                        }

                        Rectangle {
                            width: 32; height: 32; radius: 8
                            color: repeatBtn.containsMouse ? Theme.highlight : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: Theme.subtext
                                font.pixelSize: Theme.font.size.large
                                font.family: Theme.font.mono
                            }

                            MouseArea {
                                id: repeatBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { repeatProc.running = true }
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: shuffleProc;  command: ["playerctl", "shuffle", "toggle"]; running: false }
    Process { id: repeatProc;   command: ["playerctl", "loop", "toggle"]; running: false }
}
