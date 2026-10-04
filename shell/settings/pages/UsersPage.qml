import QtQuick
import "../../components"
import Quickshell.Io

import "../../services"
import "../controls"

SettingsPage {
    id: root

    property string iconDraft: ""
    property string newUsername: ""
    property string newFullName: ""
    property string pendingRemove: ""
    property string status: ""

    readonly property var me: Accounts.current()

    function initials(u) {
        if (!u) return "?"
        var parts = String(u.realName || u.name).split(" ")
        var out = ""
        for (var i = 0; i < parts.length && out.length < 2; i++)
            if (parts[i] !== "") out += parts[i][0].toUpperCase()
        return out
    }

    function refresh() { Accounts.refresh() }

    SettingSection { icon: "󰀄"; label: "CURRENT USER" }

    Rectangle {
        width: parent.width
        height: 76
        radius: Theme.shape.radius.row
        color: Theme.background

        Row {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 12

            Rectangle {
                width: 52; height: 52; radius: 26
                color: Theme.accent
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: root.initials(root.me)
                    color: Theme.background
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.family
                    font.weight: 700
                }

                Image {
                    anchors.fill: parent
                    source: root.me && root.me.icon !== "" ? "file://" + root.me.icon : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: root.me ? root.me.realName : "…"
                    color: Theme.text
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.family
                    font.weight: 700
                }

                Text {
                    text: root.me ? "@" + root.me.name + " • uid " + root.me.uid : ""
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                }
            }
        }
    }

    SettingRow {
        icon: "󰀄"
        title: "Display Name"
        subtitle: "Shown on the lock screen and greeter"
        SettingEdit {
            value: root.me ? root.me.realName : ""
            placeholder: "Full name"
            onAccepted: function(text) { root.status = Accounts.setRealName(text) ? "Name updated" : Accounts.lastError }
        }
    }

    SettingRow {
        icon: "󰋩"
        title: "Avatar"
        subtitle: root.me && root.me.icon !== "" ? root.me.icon : "Path to a PNG/JPG image"
        SettingEdit {
            value: root.iconDraft !== "" ? root.iconDraft : (root.me && root.me.icon !== "" ? root.me.icon : "")
            placeholder: "/home/…/avatar.png"
            onAccepted: function(text) { root.iconDraft = text; root.status = Accounts.setIcon(text) ? "Avatar updated" : Accounts.lastError }
        }
    }

    SettingRow {
        icon: "󰌆"
        title: "Password"
        subtitle: "Opens a terminal for pkexec passwd (root prompt)"
        SettingAction {
            label: "Set Password"
            onClicked: if (!Accounts.openPasswordTerminal(Accounts.currentUser)) root.status = Accounts.lastError
        }
    }

    SettingSection { icon: "󰀎"; label: "ALL USERS" }

    Repeater {
        model: Accounts.users

        SettingRow {
            id: userRow
            required property var modelData
            icon: userRow.modelData.current ? "󰀄" : "󰀎"
            title: userRow.modelData.realName + (userRow.modelData.current ? " (you)" : "")
            subtitle: "@" + userRow.modelData.name + " • uid " + userRow.modelData.uid + " • " + userRow.modelData.shell

            SettingAction {
                label: "Password"
                onClicked: Accounts.openPasswordTerminal(userRow.modelData.name)
            }

            SettingAction {
                visible: !userRow.modelData.current && root.pendingRemove !== userRow.modelData.name
                label: "Remove"
                onClicked: root.pendingRemove = userRow.modelData.name
            }

            SettingAction {
                visible: root.pendingRemove === userRow.modelData.name
                label: "Confirm Remove"
                onClicked: {
                    root.pendingRemove = ""
                    if (!Accounts.removeUser(userRow.modelData.name)) root.status = Accounts.lastError
                }
            }

            SettingAction {
                visible: root.pendingRemove === userRow.modelData.name
                label: "Cancel"
                onClicked: root.pendingRemove = ""
            }
        }
    }

    SettingSection { icon: "󰀔"; label: "ADD USER" }

    SettingRow {
        icon: "󰀔"
        title: "Username"
        subtitle: "Lowercase letters, digits, - and _"
        SettingEdit {
            value: root.newUsername
            placeholder: "jane"
            onAccepted: function(text) { root.newUsername = text }
        }
    }

    SettingRow {
        icon: "󰀔"
        title: "Full Name"
        subtitle: "Display name for the new account"
        SettingEdit {
            value: root.newFullName
            placeholder: "Jane Doe"
            onAccepted: function(text) { root.newFullName = text }
        }
    }

    Row {
        spacing: 8

        SettingAction {
            label: "Create User"
            accent: true
            onClicked: {
                if (Accounts.addUser(root.newUsername, root.newFullName)) {
                    root.status = "Creating " + root.newUsername + "…"
                    root.newUsername = ""
                    root.newFullName = ""
                } else {
                    root.status = Accounts.lastError
                }
            }
        }

        SettingAction {
            label: "Refresh"
            onClicked: Accounts.refresh()
        }
    }

    Text {
        width: parent.width
        text: "Creating/removing users asks for your password via pkexec. Set the new account's password afterwards — the terminal prompt handles that."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }

    Text {
        visible: root.status !== "" || Accounts.lastError !== ""
        width: parent.width
        text: root.status !== "" ? root.status : Accounts.lastError
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }
}
