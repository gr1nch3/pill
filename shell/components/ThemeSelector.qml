// Theme cards + mode/variant toggles. Shared by the standalone theme picker
// (ThemeState) and Settings → Theme. Emits themePicked; the caller decides
// whether to close the island.
import QtQuick

import "../services"

Column {
    id: root
    spacing: 14

    signal themePicked(string name)

    Grid {
        id: themeGrid
        columns: 3
        width: parent.width
        spacing: 10

        Repeater {
            model: Theme.themes

            SurfaceShape {
                id: themeCard
                required property var modelData
                shape: Theme.shape.style
                slant: Theme.shape.slant
                readonly property real _pad: Theme.shapeInset(width, height)
                property bool isActive: Theme.currentTheme === modelData.name
                property bool hovered: themeItem.containsMouse
                property bool isDynamic: modelData.name === "dynamic"
                property color swatchSurface: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.surface : modelData.surface
                property color swatchAccent: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.accent : modelData.accent
                property color swatchText: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.text : modelData.text
                property color swatchSubtext: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.subtext : modelData.subtext
                property color swatchBorder: isDynamic && ThemeEngine.loaded && ThemeEngine.palette ? ThemeEngine.palette.border : modelData.border

                width: (root.width - 20) / 3
                height: 72
                radius: Theme.shape.radius.cardLarge
                color: swatchSurface
                borderColor: isActive ? swatchAccent : (hovered ? swatchSubtext : swatchBorder)
                borderWidth: isActive ? Theme.shape.border.emphasis : Theme.shape.border.width

                Behavior on color { ColorAnimation { duration: Theme.motion.normal } }
                Behavior on borderColor { ColorAnimation { duration: Theme.motion.normal } }
                Behavior on borderWidth { NumberAnimation { duration: Theme.motion.normal } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Rectangle {
                        readonly property real _inset: Math.max(10, themeCard._pad)
                        x: _inset - 10
                        width: themeCard.width - 2 * _inset
                        height: 6
                        radius: Theme.shape.radius.hairline
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
                                width: 6; height: 6; radius: Theme.shape.radius.hairline
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
                        root.themePicked(modelData.name)
                    }
                }
            }
        }
    }

    // Shape language override ("" = the active theme's own style)
    Column {
        width: parent.width
        spacing: 6

        Text {
            text: "Shape"
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
        }

        Grid {
            width: parent.width
            columns: 3
            spacing: 8

            Repeater {
                model: [
                    { name: "",              label: "Theme" },
                    { name: "rounded",       label: "Rounded" },
                    { name: "rect",          label: "Rect" },
                    { name: "parallelogram", label: "Slant" },
                    { name: "trapezoid",     label: "Trapezoid" },
                    { name: "hex",           label: "Hex" }
                ]

                SurfaceShape {
                    required property var modelData
                    shape: Theme.shape.style
                    slant: Theme.shape.slant
                    property bool isActive: Theme.shapeStyle === modelData.name

                    width: (parent.width - 16) / 3
                    height: 26
                    radius: Theme.shape.radius.control
                    color: isActive ? Theme.accent : Theme.surfaceHover
                    Behavior on color { ColorAnimation { duration: Theme.motion.normal } }

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
                        onClicked: Theme.setShape(modelData.name)
                    }
                }
            }
        }
    }
}
