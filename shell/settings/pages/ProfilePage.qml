import QtQuick

import "../../components"

import "../../services"
import "../controls"

// Profile: the account as a page, not a form. Hero with avatar and identity,
// action tiles, then every local user as an accounts list. Edits happen in
// dialogs (name, avatar, add, remove) instead of inline rows.
SettingsPage {
    id: root

    property string status: ""
    property string statusTone: "muted"
    property string draftName: ""
    property string draftIcon: ""
    property string pendingRemove: ""
    property string newUsername: ""
    property string newFullName: ""

    readonly property var me: Accounts.current()

    // the hero above is the current account; the list is everyone else
    readonly property var otherUsers: Accounts.users.filter(function (u) {
        return !u.current;
    })

    function initials(u) {
        if (!u)
            return "?";
        var parts = String(u.realName || u.name).split(" ");
        var out = "";
        for (var i = 0; i < parts.length && out.length < 2; i++)
            if (parts[i] !== "")
                out += parts[i][0].toUpperCase();
        return out;
    }

    function shellName(s) {
        var parts = String(s).split("/");
        return parts.length > 0 ? parts[parts.length - 1] : s;
    }

    function refresh() {
        Accounts.refresh();
    }

    function openEdit() {
        if (!root.me)
            return;
        root.draftName = root.me.realName;
        root.draftIcon = root.me.icon;
        editDlg.open();
    }

    function saveEdit() {
        var ok = true;
        if (root.me && root.draftName !== root.me.realName)
            ok = Accounts.setRealName(root.draftName);
        if (ok && root.me && root.draftIcon !== "" && root.draftIcon !== root.me.icon)
            ok = Accounts.setIcon(root.draftIcon);
        root.status = ok ? "Profile updated" : Accounts.lastError;
        root.statusTone = ok ? "success" : "danger";
        editDlg.close();
    }

    function openRemove(user) {
        root.pendingRemove = user;
        removeDlg.open();
    }

    function doRemove() {
        if (root.pendingRemove === "")
            return;
        if (!Accounts.removeUser(root.pendingRemove)) {
            root.status = Accounts.lastError;
            root.statusTone = "danger";
        } else {
            root.status = "Removing " + root.pendingRemove + "…";
            root.statusTone = "muted";
        }
        removeDlg.close();
        root.pendingRemove = "";
    }

    function openAdd() {
        root.newUsername = "";
        root.newFullName = "";
        addDlg.open();
    }

    function doAdd() {
        if (Accounts.addUser(root.newUsername, root.newFullName)) {
            root.status = "Creating " + root.newUsername + "…";
            root.statusTone = "muted";
            addDlg.close();
        } else {
            root.status = Accounts.lastError;
            root.statusTone = "danger";
        }
    }

    // ── identity hero ──────────────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: 136
        radius: Theme.shape.radius.card
        color: Theme.background
        border.width: Theme.shape.border.width
        border.color: Theme.border

        Rectangle {
            id: profileCore
            anchors.fill: parent
            anchors.margins: 3
            radius: Theme.shape.radius.card - 2
            color: Theme.surface
            clip: true

            Rectangle {
                width: 190
                height: 190
                radius: 95
                color: Theme.accent
                opacity: 0.07
                anchors {
                    right: parent.right
                    rightMargin: -60
                    verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors {
                    left: parent.left
                    leftMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                spacing: 16

                // avatar: initials under the image so a missing file still reads
                Rectangle {
                    id: avatar
                    width: 78
                    height: 78
                    radius: 39
                    color: Theme.accent
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: root.initials(root.me)
                        color: Theme.background
                        font.pixelSize: Theme.font.size.xlarge
                        font.family: Theme.font.family
                        font.weight: 800
                    }

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        // a stale IconFile (missing file) must fall back to the
                        // initials: hide the image, never rewrite its source
                        property string failedFor: ""
                        source: root.me && root.me.icon !== "" ? "file://" + root.me.icon : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: avatarImg.status === Image.Ready && avatarImg.failedFor !== (root.me ? root.me.icon : "")
                        onStatusChanged: if (status === Image.Error && root.me)
                            avatarImg.failedFor = root.me.icon
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openEdit()
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: root.me ? root.me.realName : "Loading…"
                        color: Theme.text
                        font.pixelSize: 26
                        font.family: Theme.font.family
                        font.weight: 800
                    }

                    Text {
                        text: root.me ? "@" + root.me.name + " · uid " + root.me.uid : ""
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                    }

                    Row {
                        spacing: 6
                        topPadding: 2

                        Rectangle {
                            width: shellBadge.implicitWidth + 14
                            height: 20
                            radius: Theme.shape.radius.hairline
                            color: Theme.highlight
                            Text {
                                id: shellBadge
                                anchors.centerIn: parent
                                text: root.me ? root.shellName(root.me.shell) : ""
                                color: Theme.text
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.mono
                            }
                        }

                        Rectangle {
                            visible: root.me
                            width: uidBadge.implicitWidth + 14
                            height: 20
                            radius: Theme.shape.radius.hairline
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                            border.width: Theme.shape.border.width
                            border.color: Theme.accent
                            Text {
                                id: uidBadge
                                anchors.centerIn: parent
                                text: "SIGNED IN"
                                color: Theme.accent
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                font.weight: 800
                                font.letterSpacing: 0.6
                            }
                        }
                    }
                }
            }

            SettingAction {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 18
                }
                label: "Edit Profile"
                accent: true
                onClicked: root.openEdit()
            }
        }
    }

    // ── actions as tiles, not rows ─────────────────────────────────────────
    Row {
        width: parent.width
        spacing: 8

        SettingTile {
            width: (parent.width - 16) / 3
            icon: "󰀄"
            title: "Edit Profile"
            hint: "Name and avatar"
            onClicked: root.openEdit()
        }

        SettingTile {
            width: (parent.width - 16) / 3
            icon: "󰌆"
            title: "Set Password"
            hint: "Opens pkexec passwd"
            onClicked: if (!Accounts.openPasswordTerminal(Accounts.currentUser)) {
                root.status = Accounts.lastError;
                root.statusTone = "danger";
            }
        }

        SettingTile {
            width: (parent.width - 16) / 3
            icon: "󰑓"
            title: "Refresh"
            hint: Accounts.users.length + " account(s)"
            onClicked: root.refresh()
        }
    }

    SettingSection {
        icon: "󰀎"
        label: "ACCOUNTS"
        description: "Other local users (uid 1000+). Password changes open a terminal; removal asks first."
    }

    SettingNote {
        visible: root.otherUsers.length === 0 && Accounts.users.length > 0
        text: "No other accounts on this machine yet."
    }

    Repeater {
        model: root.otherUsers

        SettingRow {
            id: userRow
            required property var modelData
            icon: root.initials(userRow.modelData)
            title: userRow.modelData.realName
            subtitle: "@" + userRow.modelData.name + " · uid " + userRow.modelData.uid + " · " + root.shellName(userRow.modelData.shell)

            SettingAction {
                label: "Password"
                onClicked: Accounts.openPasswordTerminal(userRow.modelData.name)
            }

            SettingAction {
                label: "Remove"
                danger: true
                onClicked: root.openRemove(userRow.modelData.name)
            }
        }
    }

    SettingTile {
        width: parent.width
        height: 66
        icon: "󰀔"
        title: "Add User"
        hint: "Username and full name"
        onClicked: root.openAdd()
    }

    SettingNote {
        tone: root.statusTone
        text: root.status
    }

    // ── dialogs ────────────────────────────────────────────────────────────
    SettingDialog {
        id: editDlg
        title: "Edit Profile"
        description: "The display name and avatar the lock screen and greeter show."

        Column {
            width: parent.width
            spacing: 5

            Text {
                text: "DISPLAY NAME"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.family
                font.weight: 700
                font.letterSpacing: 0.8
            }

            SettingEdit {
                width: parent.width
                textAlign: Text.AlignLeft
                value: root.draftName
                placeholder: "Full name"
                onAccepted: function (text) {
                    root.draftName = text;
                }
            }
        }

        Column {
            width: parent.width
            spacing: 5

            Text {
                text: "AVATAR PATH"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.family
                font.weight: 700
                font.letterSpacing: 0.8
            }

            SettingEdit {
                width: parent.width
                textAlign: Text.AlignLeft
                value: root.draftIcon
                placeholder: "/home/…/avatar.png"
                onAccepted: function (text) {
                    root.draftIcon = text;
                }
            }

            SettingNote {
                text: "Leave the path empty to keep the initials circle."
            }
        }

        Item {
            width: parent.width
            height: 30

            Row {
                anchors.right: parent.right
                spacing: 8

                SettingAction {
                    label: "Cancel"
                    onClicked: editDlg.close()
                }
                SettingAction {
                    label: "Save"
                    accent: true
                    onClicked: root.saveEdit()
                }
            }
        }
    }

    SettingDialog {
        id: addDlg
        title: "Add User"
        description: "Creates the account with pkexec useradd. Set its password from the account row afterwards."

        Column {
            width: parent.width
            spacing: 5

            Text {
                text: "USERNAME"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.family
                font.weight: 700
                font.letterSpacing: 0.8
            }

            SettingEdit {
                width: parent.width
                textAlign: Text.AlignLeft
                value: root.newUsername
                placeholder: "jane"
                onAccepted: function (text) {
                    root.newUsername = text;
                }
            }

            SettingNote {
                tone: "danger"
                visible: root.newUsername !== "" && !Accounts.validUsername(root.newUsername)
                text: "Lowercase letters, digits, - and _ (3-32 chars)."
            }
        }

        Column {
            width: parent.width
            spacing: 5

            Text {
                text: "FULL NAME"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.caption
                font.family: Theme.font.family
                font.weight: 700
                font.letterSpacing: 0.8
            }

            SettingEdit {
                width: parent.width
                textAlign: Text.AlignLeft
                value: root.newFullName
                placeholder: "Jane Doe"
                onAccepted: function (text) {
                    root.newFullName = text;
                }
            }
        }

        Item {
            width: parent.width
            height: 30

            Row {
                anchors.right: parent.right
                spacing: 8

                SettingAction {
                    label: "Cancel"
                    onClicked: addDlg.close()
                }
                SettingAction {
                    label: "Create"
                    accent: true
                    interactive: Accounts.validUsername(root.newUsername)
                    onClicked: root.doAdd()
                }
            }
        }
    }

    SettingDialog {
        id: removeDlg
        title: "Remove " + root.pendingRemove + "?"
        description: "Deletes the account and its home directory. This cannot be undone."

        Item {
            width: parent.width
            height: 30

            Row {
                anchors.right: parent.right
                spacing: 8

                SettingAction {
                    label: "Cancel"
                    onClicked: removeDlg.close()
                }
                SettingAction {
                    label: "Remove Account"
                    danger: true
                    onClicked: root.doRemove()
                }
            }
        }
    }
}
