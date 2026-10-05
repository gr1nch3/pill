import QtQuick

import "../utils"

// One notification entry: icon tile + app/summary/body column with an
// optional dismiss button. Used by the notifications pill and the control
// center list.
Item {
    id: row

    property var notification: null
    property bool expanded: false        // show the body line(s)
    property int bodyLines: 1
    property bool showDismiss: false
    property real iconSize: 32
    property real iconRadius: 8
    property color titleColor: Theme.text
    property color subtextColor: Theme.subtext
    signal dismissed

    implicitHeight: Math.max(row.iconSize, textCol.implicitHeight)
    implicitWidth: 200

    NotifIcon {
        id: icon
        width: row.iconSize
        height: row.iconSize
        radius: row.iconRadius
        anchors.verticalCenter: parent.verticalCenter
        appIcon: row.notification ? (row.notification.appIcon || "") : ""
        appName: row.notification ? (row.notification.appName || "") : ""
        urgency: row.notification ? (row.notification.urgency || 0) : 0
    }

    Column {
        id: textCol
        anchors {
            left: icon.right
            leftMargin: 8
            right: row.showDismiss ? dismissBtn.left : parent.right
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        Text {
            width: parent.width
            text: row.notification ? (row.notification.appName || "notification") : ""
            color: row.subtextColor
            font.pixelSize: Theme.font.size.caption
            font.family: Theme.font.family
            font.weight: 500
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: row.notification ? (row.notification.summary || "") : ""
            color: row.titleColor
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            font.weight: 500
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: row.expanded && row.notification && row.notification.body !== ""
            text: row.notification ? (row.notification.body || "") : ""
            color: row.subtextColor
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            elide: Text.ElideRight
            maximumLineCount: row.bodyLines
            wrapMode: Text.WordWrap
        }
    }

    Text {
        id: dismissBtn
        visible: row.showDismiss
        anchors {
            right: parent.right
            top: parent.top
        }
        text: Icons.close
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.mono
        color: dismissMouse.containsMouse ? Theme.danger : Theme.subtext
        Behavior on color {
            ColorAnimation {
                duration: Theme.motion.hover
            }
        }

        MouseArea {
            id: dismissMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.dismissed()
        }
    }
}
