import QtQuick
import QtQuick.Controls

import "../../components"

// Modal settings dialog: dimmed backdrop, double-bezel card, spring-ish
// entrance. Declared next to the page that uses it; a Popup so it escapes the
// page's clipping and scroll area. Esc or a click outside closes it.
// Put the body (fields, buttons) directly inside:
//
//   SettingDialog {
//       id: editDlg
//       title: "Edit profile"
//       SettingEdit { ... }
//   }
Popup {
    id: dialog

    property string title: ""
    property string description: ""

    default property alias body: bodyColumn.data

    modal: true
    dim: true
    padding: 0
    width: 420
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.motion.fast
        }
        NumberAnimation {
            property: "scale"
            from: 0.95
            to: 1
            duration: Theme.motion.panel
            easing.type: Easing.OutCubic
        }
    }
    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Theme.motion.fast
        }
    }

    background: Item {
        // shell + core, the same nested read as every other card
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: Theme.shape.radius.card + 4
            color: Theme.background
            border.width: Theme.shape.border.width
            border.color: Theme.border
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.shape.radius.card
            color: Theme.surface
        }
    }

    contentItem: Item {
        implicitWidth: dialog.width
        implicitHeight: content.implicitHeight + 40

        Column {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 20
            }
            spacing: 14

            Column {
                width: parent.width
                spacing: 4

                Text {
                    width: parent.width - 24
                    text: dialog.title
                    color: Theme.text
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.family
                    font.weight: 700
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: dialog.description !== ""
                    text: dialog.description
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    wrapMode: Text.WordWrap
                }
            }

            Column {
                id: bodyColumn
                width: parent.width
                spacing: 10
            }
        }

        Text {
            anchors {
                right: parent.right
                top: parent.top
                margins: 12
            }
            text: "󰅖"
            color: closeMouse.containsMouse ? Theme.text : Theme.subtext
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.mono
            Behavior on color {
                ColorAnimation {
                    duration: Theme.motion.hover
                }
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dialog.close()
            }
        }
    }
}
