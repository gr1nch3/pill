import QtQuick
import Qt5Compat.GraphicalEffects

import "../services"
import "../components"
import "../utils"
import "../eyes"

Item {
    id: root
    anchors.fill: parent

    opacity: IslandState.state === "theme" ? 1 : 0
    visible: opacity > 0
    focus: visible
    Keys.onEscapePressed: IslandState.closeToIdle()
    Behavior on opacity { NumberAnimation { duration: 150 } }

    property real contentHeight: themeCol.implicitHeight + 32


    Column {
        id: themeCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 14

        Row {
            width: parent.width
            anchors.left: parent.left
            spacing: 8

            Eye {
                eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
                anchors.verticalCenter: parent.verticalCenter
                moods: Theme.eyeMoods
                mood: "active"
            }

            Text {
                id: themeTitle
                text: "Theme"
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Grid {
            id: themeGrid
            columns: 3
            width: parent.width
            spacing: 10

            Repeater {
                model: Theme.themes

                Rectangle {
                    required property var modelData
                    property bool isActive: Theme.currentTheme === modelData.name
                    property bool hovered: themeItem.containsMouse
                    property bool isDynamic: modelData.name === "dynamic"
                    property color swatchSurface: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.surface : modelData.surface
                    property color swatchAccent: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.accent : modelData.accent
                    property color swatchText: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.text : modelData.text
                    property color swatchSubtext: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.subtext : modelData.subtext
                    property color swatchBorder: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.border : modelData.border

                    width: (themeCol.width - 20) / 3
                    height: 72
                    radius: 14
                    color: swatchSurface
                    border.color: isActive ? swatchAccent : (hovered ? swatchSubtext : swatchBorder)
                    border.width: isActive ? 2 : 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: swatchAccent
                        }

                        Text {
                            text: modelData.label
                            color: swatchText
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.family
                            font.weight: 500
                        }

                        Row {
                            spacing: 4
                            Repeater {
                                model: [
                                    isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.accentAlt : modelData.accentAlt,
                                    isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.danger : modelData.danger,
                                    swatchText
                                ]
                                Rectangle {
                                    required property var modelData
                                    width: 6; height: 6; radius: 3
                                    color: modelData
                                }
                            }
                        }
                    }

                    Text {
                        visible: isActive
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        text: "✓"
                        color: swatchAccent
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                        font.weight: 700
                    }

                    MouseArea {
                        id: themeItem
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Theme.setTheme(modelData.name)
                            IslandState.closeToIdle()
                        }
                    }
                }
            }
        }

        // Mode toggle
        Column {
            width: parent.width
            spacing: 6
            visible: Theme.currentTheme === "dynamic"

            Text {
                text: "Mode"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
            }

            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        { name: "auto", label: "Auto" },
                        { name: "light", label: "Light" },
                        { name: "dark", label: "Dark" }
                    ]

                    Rectangle {
                        required property var modelData
                        property bool isActive: Theme.themeMode === modelData.name

                        width: (parent.width - 16) / 3
                        height: 28
                        radius: 8
                        color: isActive ? Theme.accent : Theme.surfaceHover

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: isActive ? Theme.background : Theme.text
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.family
                            font.weight: 500
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.setMode(modelData.name)
                        }
                    }
                }
            }
        }

        // Variant toggle
        Column {
            width: parent.width
            spacing: 6
            visible: Theme.currentTheme === "dynamic"

            Text {
                text: "Variant"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
            }

            Grid {
                width: parent.width
                columns: 3
                spacing: 8

                Repeater {
                    model: Theme.availableVariants

                    Rectangle {
                        required property var modelData
                        property bool isActive: Theme.themeVariant === modelData.name

                        width: (parent.width - 16) / 3
                        height: 26
                        radius: 8
                        color: isActive ? Theme.accent : Theme.surfaceHover

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: isActive ? Theme.background : Theme.text
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.family
                            font.weight: 500
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.setVariant(modelData.name)
                        }
                    }
                }
            }
        }
    }
}
