import QtQuick
import "../../components"

import "../../services"

// One full-width settings row: icon, title, description, and a right-aligned
// control slot (declare children directly). Hides itself while a settings
// search doesn't match title/subtitle, or while visibleWhen is false.
Rectangle {
    id: row
    default property alias action: slotRow.data
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool visibleWhen: true

    readonly property bool matchesSearch: SettingsSearch.text === ""
        || (title + " " + subtitle).toLowerCase().indexOf(SettingsSearch.text.toLowerCase()) !== -1

    width: parent.width
    height: subtitle !== "" ? 56 : 42
    radius: Theme.shape.radius.row
    color: rowMouse.containsMouse ? Theme.surfaceHover : "transparent"
    visible: matchesSearch && visibleWhen
    Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

    Text {
        id: rowIcon
        text: row.icon
        visible: row.icon !== ""
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        color: Theme.text
        font.pixelSize: Theme.font.size.xlarge
        font.family: Theme.font.mono
    }

    Column {
        anchors {
            left: rowIcon.visible ? rowIcon.right : parent.left
            leftMargin: 10
            right: slotHost.left
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 1

        Text {
            width: parent.width
            text: row.title
            color: Theme.text
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family
            font.weight: 500
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: row.subtitle
            visible: row.subtitle !== ""
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            elide: Text.ElideRight
        }
    }

    Item {
        id: slotHost
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        implicitWidth: slotRow.implicitWidth
        implicitHeight: slotRow.implicitHeight

        Row {
            id: slotRow
            anchors.centerIn: parent
            spacing: 8
        }
    }

    MouseArea {
        id: rowMouse
        z: -1
        anchors.fill: parent
        hoverEnabled: true
    }
}
