import QtQuick
import QtQuick.Controls

import "../../components"

// Dropdown for option sets too long for chips (keyboard layouts, profiles…).
// Options are plain strings or { value, label }; the button shows the label for
// currentValue and falls back to the raw value when it is not in the list.
Item {
    id: select

    property var options: []
    property var currentValue: undefined
    property string placeholder: "—"
    signal valueSelected(var value)

    width: 200
    height: 32

    function _label(opt) {
        return typeof opt === "string" ? opt : opt.label
    }

    function _value(opt) {
        return typeof opt === "string" ? opt : opt.value
    }

    function currentLabel() {
        for (var i = 0; i < options.length; i++)
            if (_value(options[i]) === currentValue) return _label(options[i])
        return currentValue !== undefined && currentValue !== "" ? String(currentValue) : placeholder
    }

    Rectangle {
        id: button
        anchors.fill: parent
        radius: Theme.shape.radius.control
        color: selectMouse.containsMouse || popup.visible ? Theme.surfaceHover : Theme.background
        border.width: popup.visible ? Theme.shape.border.emphasis : Theme.shape.border.width
        border.color: popup.visible ? Theme.accent : (selectMouse.containsMouse ? Theme.subtext : Theme.border)
        Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
        Behavior on border.color { ColorAnimation { duration: Theme.motion.hover } }

        Row {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 6

            Text {
                width: parent.width - 18
                text: select.currentLabel()
                color: Theme.text
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "󰅀"
                color: popup.visible ? Theme.accent : Theme.subtext
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.mono
                anchors.verticalCenter: parent.verticalCenter
                rotation: popup.visible ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.motion.normal; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: selectMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible ? popup.close() : popup.open()
        }
    }

    Popup {
        id: popup
        y: select.height + 4
        width: select.width
        padding: 4

        // the pane may close while the list is open; don't leave it floating
        Connections {
            target: IslandState
            function onStateChanged() { if (IslandState.state !== "settings") popup.close() }
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion.fast }
            NumberAnimation { property: "scale"; from: 0.98; to: 1; duration: Theme.motion.normal; easing.type: Easing.OutCubic }
        }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.motion.fast } }

        background: Rectangle {
            radius: Theme.shape.radius.row
            color: Theme.surface
            border.width: Theme.shape.border.width
            border.color: Theme.border
        }

        contentItem: Flickable {
            implicitWidth: select.width
            implicitHeight: Math.min(optionColumn.implicitHeight, 240)
            contentWidth: width
            contentHeight: optionColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: optionColumn
                width: parent.width

                Repeater {
                    model: select.options

                    delegate: Rectangle {
                        id: optionRow
                        required property var modelData
                        readonly property bool on: select._value(modelData) === select.currentValue
                        width: optionColumn.width
                        height: 30
                        radius: Theme.shape.radius.hairline
                        color: optMouse.containsMouse ? Theme.surfaceHover
                            : (on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

                        Text {
                            anchors { left: parent.left; leftMargin: 10; right: optCheck.left; verticalCenter: parent.verticalCenter }
                            text: select._label(optionRow.modelData)
                            color: optionRow.on ? Theme.accent : Theme.text
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.family
                            font.weight: optionRow.on ? 700 : 400
                            elide: Text.ElideRight
                        }

                        Text {
                            id: optCheck
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            text: "✓"
                            visible: optionRow.on
                            color: Theme.accent
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.family
                            font.weight: 800
                        }

                        MouseArea {
                            id: optMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                select.valueSelected(select._value(optionRow.modelData))
                                popup.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
