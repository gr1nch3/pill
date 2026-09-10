import QtQuick

import "../services"
import "../components"
import "../utils"
import "../eyes"

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 16

    opacity: IslandState.state === "settings" ? 1 : 0
    visible: opacity > 0
    focus: visible
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Keys.onEscapePressed: IslandState.closeToIdle()

    property int currentTab: 0
    readonly property var tabNames: ["Layout", "Font", "Behaviour", "Advanced"]
    readonly property int contentHeight: [2, 2, 3, 5][root.currentTab] * 66 + 120



    Column {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        // ── Title bar ──────────────────────────────────────────────────────
        Item {
            width: parent.width; height: 32

            BackButton {
                id: backIcon
                anchors.verticalCenter: parent.verticalCenter
                onClicked: IslandState.closeToIdle()
            }

            Eye {
                id: setEyes
                eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: backIcon.right; anchors.leftMargin: 8
                moods: Theme.eyeMoods
                mood: "active"
            }

            Text {
                text: "Settings"
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: setEyes.right; anchors.leftMargin: 8
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.border; opacity: 0.5 }

        // ── Tab bar ────────────────────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.tabNames
                delegate: Rectangle {
                    required property int index
                    required property string modelData
                    width: (parent.parent.width - 12) / 4
                    height: 32; radius: 8
                    color: index === root.currentTab ? Theme.accent : (tabHover.containsMouse ? Theme.surfaceHover : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: index === root.currentTab ? Theme.background : Theme.text
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                        font.weight: index === root.currentTab ? 700 : 500
                    }

                    MouseArea {
                        id: tabHover
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = index
                    }
                }
            }
        }

        // ── Tab content ────────────────────────────────────────────────────
        // Layout tab ─────────────────────────────────────────────────────────
        Grid {
            columns: 2; spacing: 8
            width: parent.width
            visible: root.currentTab === 0

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰐃"
                tileTitle: "Pinned"
                tileSubtitle: Config.pinned ? "Always visible" : "Auto-hides"
                tileActive: Config.pinned
                onClicked: { Config.pinned = !Config.pinned; Config.save() }
            }

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰇄"
                tileTitle: "Pin Mode"
                tileSubtitle: Config.pinMode === "bar" ? "Reserves space" : "Floating"
                tileActive: Config.pinMode === "bar"
                onClicked: { Config.pinMode = Config.pinMode === "bar" ? "overlay" : "bar"; Config.save() }
            }

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰍎"
                tileTitle: "Position"
                tileSubtitle: Config.position.charAt(0).toUpperCase() + Config.position.slice(1)
                tileActive: Config.position === "top"
                onClicked: {
                    var positions = ["top", "bottom"]
                    var idx = positions.indexOf(Config.position)
                    Config.position = positions[(idx + 1) % positions.length]
                    Config.save()
                }
            }
        }

        // Font tab ──────────────────────────────────────────────────────────
        Grid {
            columns: 2; spacing: 8
            width: parent.width
            visible: root.currentTab === 1

            StringTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰎆"
                tileTitle: "Font"
                tileValue: Config.fontFamily || "(system)"
                onValueAccepted: function(val) { Config.fontFamily = val; Config.save() }
            }

            StringTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰋜"
                tileTitle: "Icon Font"
                tileValue: Config.iconFontFamily
                onValueAccepted: function(val) { Config.iconFontFamily = val; Config.save() }
            }

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰁃"
                tileTitle: "Font Scale"
                tileSubtitle: Config.fontScale.toFixed(1) + "x"
                editable: true
                tileStep: 0.1
                onPlusClicked: { Config.fontScale = Math.min(Config.fontScale + 0.1, 2.0); Config.save() }
                onMinusClicked: { Config.fontScale = Math.max(Config.fontScale - 0.1, 0.5); Config.save() }
            }
        }

        // Behaviour tab ─────────────────────────────────────────────────────
        Grid {
            columns: 2; spacing: 8
            width: parent.width
            visible: root.currentTab === 2

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰥔"
                tileTitle: "Auto-hide"
                tileSubtitle: (Config.autoHideDelay / 1000).toFixed(1) + "s"
                editable: true; tileStep: 100
                onPlusClicked: { Config.autoHideDelay = Math.min(Config.autoHideDelay + 100, 10000); Config.save() }
                onMinusClicked: { Config.autoHideDelay = Math.max(Config.autoHideDelay - 100, 100); Config.save() }
            }

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰼰"
                tileTitle: "Show Delay"
                tileSubtitle: (Config.showDelay / 1000).toFixed(1) + "s"
                editable: true; tileStep: 50
                onPlusClicked: { Config.showDelay = Math.min(Config.showDelay + 50, 5000); Config.save() }
                onMinusClicked: { Config.showDelay = Math.max(Config.showDelay - 50, 0); Config.save() }
            }

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰅶"
                tileTitle: "OSD Timeout"
                tileSubtitle: (Config.osdTimeout / 1000).toFixed(1) + "s"
                editable: true; tileStep: 100
                onPlusClicked: { Config.osdTimeout = Math.min(Config.osdTimeout + 100, 10000); Config.save() }
                onMinusClicked: { Config.osdTimeout = Math.max(Config.osdTimeout - 100, 500); Config.save() }
            }

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰂢"
                tileTitle: "Notif. Timeout"
                tileSubtitle: (Config.notificationTimeout / 1000).toFixed(1) + "s"
                editable: true; tileStep: 100
                onPlusClicked: { Config.notificationTimeout = Math.min(Config.notificationTimeout + 100, 30000); Config.save() }
                onMinusClicked: { Config.notificationTimeout = Math.max(Config.notificationTimeout - 100, 1000); Config.save() }
            }

            SettingTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰉁"
                tileTitle: "Max Notifications"
                tileSubtitle: Config.maxNotifications.toString()
                editable: true; tileStep: 1
                onPlusClicked: { Config.maxNotifications = Math.min(Config.maxNotifications + 1, 200); Config.save() }
                onMinusClicked: { Config.maxNotifications = Math.max(Config.maxNotifications - 1, 1); Config.save() }
            }
        }

        // Advanced tab ──────────────────────────────────────────────────────
        Grid {
            columns: 2; spacing: 8
            width: parent.width
            visible: root.currentTab === 3

            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰸉"
                tileTitle: "Wallpapers"
                tileValue: Config.wallpaperDir
            }

            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰹑"
                tileTitle: "Screenshots"
                tileValue: Config.screenshotDir
            }

            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰎁"
                tileTitle: "Recordings"
                tileValue: Config.recordingDir
            }

            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰓃"
                tileTitle: "Cava Config"
                tileValue: Config.cavaConfig
            }

            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰍃"
                tileTitle: "Lock"
                tileValue: Config.sessionLock.join(" ")
            }

            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰍃"
                tileTitle: "Logout"
                tileValue: Config.sessionLogout.join(" ")
            }
            
            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰤄"
                tileTitle: "Suspend"
                tileValue: Config.sessionSuspend.join(" ")
            }
            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰤆"
                tileTitle: "Shutdown"
                tileValue: Config.sessionShutdown.join(" ")
            }

            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰤄"
                tileTitle: "Hibernate"
                tileValue: Config.sessionHibernate.join(" ")
            }

            InfoTile {
                width: (parent.width - parent.spacing) / 2
                tileIcon: "󰑐"
                tileTitle: "Reboot"
                tileValue: Config.sessionReboot.join(" ")
            }
        }
    }

    // ── Reusable components ────────────────────────────────────────────────

    component SettingTile: Rectangle {
        id: tileRoot
        height: 56; radius: 12
        color: tileMouse.containsMouse ? Theme.surfaceHover : Theme.background
        Behavior on color { ColorAnimation { duration: 100 } }

        property string tileIcon: ""
        property string tileTitle: ""
        property string tileSubtitle: ""
        property bool tileActive: false
        property bool editable: false
        property real tileStep: 100
        signal clicked
        signal plusClicked
        signal minusClicked

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 10

            Text {
                text: tileRoot.tileIcon
                font.pixelSize: Theme.font.size.xlarge
                font.family: Theme.font.mono
                color: tileRoot.tileActive ? Theme.accent : Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: tileRoot.editable ? parent.width - 110 : parent.width - 26
                spacing: 2

                Text {
                    width: parent.width
                    text: tileRoot.tileTitle
                    color: Theme.text
                    font.pixelSize: Theme.font.size.normal
                    font.family: Theme.font.family
                    font.weight: 500
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: tileRoot.tileSubtitle
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    elide: Text.ElideRight
                }
            }

            Item { width: 1; height: 1; visible: tileRoot.editable }

            Row {
                visible: tileRoot.editable
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Rectangle {
                    width: 28; height: 22; radius: 6
                    color: plusMouse.containsMouse ? Theme.accent : Theme.surfaceHover
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: plusMouse.containsMouse ? Theme.background : Theme.text
                        font.pixelSize: Theme.font.size.normal
                        font.family: Theme.font.family
                        font.weight: 800
                    }
                    MouseArea {
                        id: plusMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: tileRoot.plusClicked()
                    }
                }

                Rectangle {
                    width: 28; height: 22; radius: 6
                    color: minusMouse.containsMouse ? Theme.accent : Theme.surfaceHover
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: "-"
                        color: minusMouse.containsMouse ? Theme.background : Theme.text
                        font.pixelSize: Theme.font.size.normal
                        font.family: Theme.font.family
                        font.weight: 800
                    }
                    MouseArea {
                        id: minusMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: tileRoot.minusClicked()
                    }
                }
            }
        }

        MouseArea {
            id: tileMouse
            z: -1
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: tileRoot.clicked()
        }
    }

    component StringTile: Rectangle {
        id: strTile
        height: 56; radius: 12
        color: strMouse.containsMouse ? Theme.surfaceHover : Theme.background
        Behavior on color { ColorAnimation { duration: 100 } }

        property string tileIcon: ""
        property string tileTitle: ""
        property string tileValue: ""
        signal valueAccepted(string val)

        property bool editing: false
        onTileValueChanged: editing = false
        onVisibleChanged: if (!visible && editing) { editing = false }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 10

            Text {
                text: strTile.tileIcon
                font.pixelSize: Theme.font.size.xlarge
                font.family: Theme.font.mono
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 26
                spacing: 2

                Text {
                    width: parent.width
                    text: strTile.tileTitle
                    color: Theme.text
                    font.pixelSize: Theme.font.size.normal
                    font.family: Theme.font.family
                    font.weight: 500
                    elide: Text.ElideRight
                }

                TextInput {
                    id: inputField
                    width: parent.width
                    text: strTile.tileValue
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    readOnly: !strTile.editing
                    clip: true
                    selectByMouse: true
                    activeFocusOnTab: false
                    visible: strTile.editing

                    onAccepted: {
                        strTile.valueAccepted(text)
                        strTile.editing = false
                    }
                    onEditingFinished: {
                        if (strTile.editing) {
                            strTile.valueAccepted(text)
                            strTile.editing = false
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: strTile.tileValue
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    elide: Text.ElideRight
                    visible: !strTile.editing
                }
            }
        }

        MouseArea {
            id: strMouse
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                strTile.editing = true
                inputField.forceActiveFocus()
                inputField.selectAll()
            }
        }
    }

    component InfoTile: Rectangle {
        id: infoTile
        height: 56; radius: 12
        color: Theme.background

        property string tileIcon: ""
        property string tileTitle: ""
        property string tileValue: ""

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 10

            Text {
                text: infoTile.tileIcon
                font.pixelSize: Theme.font.size.xlarge
                font.family: Theme.font.mono
                color: Theme.subtext
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 26
                spacing: 2

                Text {
                    width: parent.width
                    text: infoTile.tileTitle
                    color: Theme.text
                    font.pixelSize: Theme.font.size.normal
                    font.family: Theme.font.family
                    font.weight: 500
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: infoTile.tileValue
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.mono
                    elide: Text.ElideRight
                }
            }
        }
    }
}
