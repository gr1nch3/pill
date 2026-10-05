import QtQuick
import "../../components"

// Inline text field: a real box (background, border, focus ring) so forms read
// as forms in dialogs and settings rows alike. Commits once, on Enter or focus
// loss (onEditingFinished covers both; onAccepted would double-fire).
Item {
    id: edit
    property string value: ""
    property string placeholder: ""
    property int echoMode: TextInput.Normal
    property int textAlign: Text.AlignLeft
    // live: emit textEdited on every keystroke (filters, passwords) instead of
    // only committing on Enter/focus loss.
    property bool live: false
    signal accepted(string text)
    signal textEdited(string text)

    function focusInput() { input.forceActiveFocus() }

    width: 220
    height: 32

    Rectangle {
        id: field
        anchors.fill: parent
        radius: Theme.shape.radius.control
        color: Theme.background
        border.width: input.activeFocus ? Theme.shape.border.emphasis : Theme.shape.border.width
        border.color: input.activeFocus ? Theme.accent
            : (editHover.hovered ? Theme.subtext : Theme.border)
        Behavior on border.color { ColorAnimation { duration: Theme.motion.hover } }
        Behavior on border.width { NumberAnimation { duration: Theme.motion.hover } }

        // live caret rail while editing
        Rectangle {
            visible: input.activeFocus
            anchors {
                left: parent.left; right: parent.right; bottom: parent.bottom
                leftMargin: 8; rightMargin: 8; bottomMargin: 4
            }
            height: 2
            radius: 1
            color: Theme.accent
            opacity: 0.55
        }

        Text {
            anchors {
                left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                leftMargin: 10; rightMargin: 10
            }
            text: edit.value !== "" ? edit.value : edit.placeholder
            color: edit.value !== "" ? Theme.text : Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            horizontalAlignment: edit.textAlign
            elide: Text.ElideRight
            visible: !input.activeFocus
        }

        TextInput {
            id: input
            anchors {
                left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                leftMargin: 10; rightMargin: 10
            }
            color: Theme.text
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            horizontalAlignment: edit.textAlign
            echoMode: edit.echoMode
            clip: true
            selectByMouse: true
            activeFocusOnTab: false
            visible: activeFocus
            selectionColor: Theme.accent
            selectedTextColor: Theme.background

            onEditingFinished: edit.accepted(text)
            onTextChanged: if (edit.live) edit.textEdited(text)

            Connections {
                target: edit
                function onValueChanged() { if (!input.activeFocus) input.text = edit.value }
            }

            Component.onCompleted: text = edit.value
        }
    }

    HoverHandler { id: editHover; cursorShape: Qt.IBeamCursor }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: {
            input.forceActiveFocus()
            input.selectAll()
        }
    }
}
