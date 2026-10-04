import QtQuick
import "../../components"

// Right-aligned inline text editor for a settings row. Commits once, on Enter
// or focus loss (onEditingFinished covers both; onAccepted would double-fire).
Item {
    id: edit
    property string value: ""
    property string placeholder: ""
    property int echoMode: TextInput.Normal
    signal accepted(string text)

    width: 220
    height: 26

    Text {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: parent.width
        text: edit.value !== "" ? edit.value : edit.placeholder
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        visible: !input.activeFocus
    }

    TextInput {
        id: input
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: parent.width
        color: Theme.text
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        horizontalAlignment: Text.AlignRight
        echoMode: edit.echoMode
        clip: true
        selectByMouse: true
        activeFocusOnTab: false
        visible: activeFocus

        onEditingFinished: edit.accepted(text)

        Connections {
            target: edit
            function onValueChanged() { input.text = edit.value }
        }

        Component.onCompleted: text = edit.value
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: {
            input.forceActiveFocus()
            input.selectAll()
        }
    }
}
