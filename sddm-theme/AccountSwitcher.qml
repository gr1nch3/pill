// Account switcher — SDDM greeter ONLY (PRD §6.6).
// Present by input, not by default: a dot row at rest (hidden entirely when
// the machine has exactly one account), transient avatar+name on arrow-key
// cycling, fading back to dots after a short timeout.
// Keyboard-first: SDDM runs pre-compositor. Click/tap on dots also works.

import QtQuick

Item {
    id: root

    property var userModel: null
    property var pal: null            // palette from Main.qml
    signal userPicked(string name)

    readonly property int accountCount: userModel ? userModel.count : 0
    property int selection: 0
    property string accentColor: pal ? pal.accent : "#4ecdc4"
    property string textColor: pal ? pal.text : "#f0f0f5"

    // Filled in as delegates complete; index-aligned with the model rows.
    property var _names: []
    property var _icons: []

    implicitWidth: Math.max(dots.width, info.width)
    implicitHeight: 48
    visible: accountCount > 1

    // ── At-rest affordance: one dot per account ────────────────────────────
    Row {
        id: dots
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 8

        Repeater {
            model: root.userModel

            Rectangle {
                required property int index
                required property string name
                required property string icon

                Component.onCompleted: {
                    if (index === root._names.length) { root._names.push(name); root._icons.push(icon) }
                    if (accountCount && name === userModel.lastUser) root.selection = index
                }

                readonly property bool selected: index === root.selection

                anchors.verticalCenter: parent.verticalCenter
                width: selected ? 10 : 7
                height: width
                radius: width / 2
                color: selected ? root.accentColor : "transparent"
                border.color: root.accentColor
                border.width: 1

                Behavior on width { NumberAnimation { duration: 120 } }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: root.select(parent.index)
                }
            }
        }
    }

    // ── Transient identity on input ────────────────────────────────────────
    Row {
        id: info
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 8
        opacity: revealTimer.running ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Initials circle when no AccountsService face icon is set (§6.6).
        Rectangle {
            width: 28; height: 28; radius: 14
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            border.color: root.accentColor
            border.width: 1
            visible: !avatar.source.toString()

            Text {
                anchors.centerIn: parent
                text: root._names[root.selection] ? root._names[root.selection].charAt(0).toUpperCase() : "?"
                color: root.accentColor
                font.pixelSize: 13
                font.weight: 700
            }
        }

        Image {
            id: avatar
            width: 28; height: 28
            fillMode: Image.PreserveAspectCrop
            source: root._icons.length > root.selection ? root._icons[root.selection] : ""
            visible: source.toString() !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root._names[root.selection] || ""
            color: root.textColor
            font.pixelSize: 14
            font.weight: 600
        }
    }

    Timer {
        id: revealTimer
        // ponytail: fixed fade-back; scale with account count if rapid
        // tapping feels twitchy (PRD §6.6 open question).
        interval: 2500
    }

    function select(i) {
        if (accountCount < 2) return
        selection = (i + accountCount) % accountCount
        userPicked(_names[selection])
        revealTimer.restart()
    }

    function cycle(dir) { select(selection + dir) }
}
