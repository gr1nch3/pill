import QtQuick
import "../../components"

import "../../services"

// Base for every settings page: a styled page header (icon, title, one-line
// description) plus visibility/sizing and the refresh-on-activation hook.
// SettingsWindow fills pageTitle/pageIcon/pageDesc from the page registry when
// it loads the page, so pages carry no nav metadata themselves.
Column {
    id: page
    property bool active: false
    property string pageIcon: ""
    property string pageTitle: ""
    property string pageDesc: ""

    visible: active
    width: parent.width
    spacing: 4

    Component.onCompleted: if (active) page.refresh()
    onActiveChanged: if (active) page.refresh()

    function refresh() {}

    // ── page header ────────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: page.pageTitle !== "" ? 88 : 0
        visible: page.pageTitle !== ""

        Rectangle {
            anchors.fill: parent
            radius: Theme.shape.radius.card
            color: Theme.background
            border.width: Theme.shape.border.width
            border.color: Theme.border
        }

        Rectangle {
            id: heroCore
            anchors.fill: parent
            anchors.margins: 3
            radius: Theme.shape.radius.card - 2
            color: Theme.surface
            clip: true

            // accent wash, bled off the right edge like a spotlight. The
            // pattern itself belongs to the panel behind the page, not here.
            Rectangle {
                width: 170; height: 170; radius: 85
                color: Theme.accent
                opacity: 0.07
                anchors { right: parent.right; rightMargin: -50; verticalCenter: parent.verticalCenter }
            }

            Row {
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                spacing: 14

                Rectangle {
                    width: 48; height: 48
                    radius: Theme.shape.radius.control
                    color: Theme.background
                    border.width: Theme.shape.border.width
                    border.color: Theme.border
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: page.pageIcon
                        color: Theme.accent
                        font.pixelSize: Theme.font.size.xlarge
                        font.family: Theme.font.mono
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: page.pageTitle
                        color: Theme.text
                        font.pixelSize: Theme.font.size.xlarge
                        font.family: Theme.font.family
                        font.weight: 800
                    }

                    Text {
                        visible: page.pageDesc !== ""
                        text: page.pageDesc
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                    }
                }
            }
        }
    }
}
