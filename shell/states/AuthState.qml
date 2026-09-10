import QtQuick
import QtQuick.Controls
import Quickshell

import "../services"
import "../components"
import "../utils"
import "../eyes"

Item {
    id: root
    anchors.fill: parent

    property QtObject flow: null

    opacity: IslandState.state === "auth" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    onVisibleChanged: {
        if (visible) passwordField.forceActiveFocus()
    }

    Keys.onEscapePressed: {
        if (root.flow) root.flow.cancelAuthenticationRequest()
        IslandState.closeToIdle()
    }

    function submit() {
        if (root.flow && passwordField.text !== "") {
            root.flow.submit(passwordField.text)
            passwordField.text = ""
        }
    }

    Connections {
        target: root.flow
        function onAuthenticationSucceeded() { IslandState.closeToIdle() }
        function onAuthenticationFailed() { passwordField.text = "" }
        function onAuthenticationRequestCancelled() { IslandState.closeToIdle() }
        function onIsCompletedChanged() {
            if (root.flow && root.flow.isCompleted && root.flow.isSuccessful)
                IslandState.closeToIdle()
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 32
        spacing: 12

        // The eyes watch you authenticate (PRD §6.3 identity surface).
        Eye {
            anchors.horizontalCenter: parent.horizontalCenter
            eyeWidth: 24; eyeHeight: 17; eyeSpacing: 12
            moods: Theme.eyeMoods
            mood: "active"
        }

        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                width: 32; height: 32; radius: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.background

                Text {
                    anchors.centerIn: parent
                    text: "󰌆"
                    font.pixelSize: Theme.font.size.large
                    font.family: Theme.font.mono
                    color: Theme.accent
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.flow ? root.flow.message || "Authentication Required" : "Authentication Required"
                color: Theme.text
                font.pixelSize: Theme.font.size.normal
                font.family: Theme.font.family
                font.weight: 500
                width: parent.width - 42
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
            opacity: 0.5
        }

        Text {
            width: parent.width
            visible: root.flow && root.flow.identities && root.flow.identities.length > 0
            text: root.flow ? "User: " + (root.flow.identities[0] ? root.flow.identities[0].displayName || "" : "") : ""
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
        }

        Rectangle {
            width: parent.width
            height: 40
            radius: 10
            color: Theme.background
            border.width: 1
            border.color: passwordField.activeFocus ? Theme.accent : Theme.border

            TextInput {
                id: passwordField
                anchors.fill: parent
                anchors.margins: 10
                color: Theme.text
                font.pixelSize: Theme.font.size.normal
                font.family: Theme.font.family
                echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                passwordCharacter: "●"
                focus: true
                onAccepted: root.submit()
                Keys.onEscapePressed: {
                    if (root.flow) root.flow.cancelAuthenticationRequest()
                    IslandState.closeToIdle()
                }
            }
        }

        Text {
            width: parent.width
            visible: root.flow && root.flow.supplementaryMessage !== ""
            text: root.flow ? root.flow.supplementaryMessage : ""
            color: root.flow && root.flow.supplementaryIsError ? Theme.danger : Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }

        Row {
            width: parent.width
            spacing: 10
            layoutDirection: Qt.RightToLeft

            Rectangle {
                width: 120
                height: 34
                radius: 10
                color: Theme.accent
                opacity: passwordField.text !== "" ? 1 : 0.5

                Text {
                    anchors.centerIn: parent
                    text: "Authenticate"
                    color: Theme.background
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submit()
                }
            }

            Rectangle {
                width: 80
                height: 34
                radius: 10
                color: Theme.background

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.flow) root.flow.cancelAuthenticationRequest()
                        IslandState.closeToIdle()
                    }
                }
            }
        }
    }
}
