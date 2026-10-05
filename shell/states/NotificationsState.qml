import QtQuick
import "../services"
import "../components"
import "../utils"
import "../eyes"

StatePane {
    id: root
    stateName: "notifications"
    radiusMode: "notifications"
    preferredWidth: root.expanded ? 420 : 360
    preferredHeight: root.contentHeight

    anchors.fill: parent

    property bool expanded: IslandState.pillExpanded
    property var latestNotif: NotificationManager.notificationList.length > 0 ? NotificationManager.notificationList[0] : null

    property real contentHeight: {
        if (!expanded || !latestNotif)
            return 64;
        var h = 28;
        h += 26 + 8 + 1 + 8;
        h += sumText.implicitHeight;
        h += 8;
        h += bodyText.implicitHeight;
        return Math.max(64, Math.min(h, 420));
    }

    // ── Compact view ───────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 10
        visible: !root.expanded && root.latestNotif !== null

        Row {
            anchors.fill: parent
            spacing: 10

            EyeFace {
                id: compactEye
                eyeWidth: 16
                eyeHeight: 12
                eyeSpacing: 7
                anchors.verticalCenter: parent.verticalCenter
                baseMood: root.latestNotif && root.latestNotif.urgency >= 2 ? "alert" : "idle"
            }

            NotificationRow {
                width: parent.width - compactEye.width - 10
                anchors.verticalCenter: parent.verticalCenter
                notification: root.latestNotif
                expanded: true
                bodyLines: 1
                iconSize: 36
                iconRadius: 10
            }
        }
    }

    // ── Expanded view: full notification body ──────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 14
        visible: root.expanded && root.latestNotif !== null

        Column {
            id: expandedContent
            width: parent.width
            spacing: 8

            Row {
                width: parent.width
                spacing: 10

                NotifIcon {
                    width: 32
                    height: 32
                    radius: Theme.shape.radius.control
                    anchors.verticalCenter: parent.verticalCenter
                    appIcon: root.latestNotif ? root.latestNotif.appIcon : ""
                    appName: root.latestNotif ? root.latestNotif.appName : ""
                    urgency: root.latestNotif ? root.latestNotif.urgency : 0
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.latestNotif ? (root.latestNotif.appName || "notification") : ""
                    color: Theme.accent
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    font.weight: 500
                    width: parent.width - 74
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: Theme.shape.radius.control
                    anchors.verticalCenter: parent.verticalCenter
                    color: dismissBtn.containsMouse ? Theme.surfaceHover : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.motion.hover
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Icons.close
                        color: dismissBtn.containsMouse ? Theme.danger : Theme.subtext
                        font.pixelSize: Theme.font.size.large
                        font.family: Theme.font.mono
                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.motion.hover
                            }
                        }
                    }
                    MouseArea {
                        id: dismissBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.latestNotif)
                                NotificationManager.dismiss(root.latestNotif.id);
                            IslandState.closeToIdle();
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
                opacity: 0.5
            }

            Text {
                id: sumText
                width: parent.width
                text: root.latestNotif ? root.latestNotif.summary : ""
                color: Theme.text
                font.pixelSize: Theme.font.size.normal
                font.family: Theme.font.family
                font.weight: 500
                wrapMode: Text.WordWrap
            }

            Text {
                id: bodyText
                width: parent.width
                visible: root.latestNotif && root.latestNotif.body !== ""
                text: root.latestNotif ? root.latestNotif.body : ""
                color: Theme.subtext
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
                wrapMode: Text.WordWrap
                lineHeight: 1.4
                maximumLineCount: 5
                elide: Text.ElideRight
            }
        }
    }
}
