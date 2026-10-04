import QtQuick
import "../../components"

// Controlled toggle: `value` is the state, `valueEdited` carries the requested
// new value. `checked`/`toggled` are the old names, kept for existing pages.
Rectangle {
    id: tog
    property bool value: false
    property alias checked: tog.value
    signal valueEdited(bool value)
    signal toggled

    width: 40; height: 22; radius: 11
    color: tog.value ? Theme.accent : Theme.surfaceHover
    border.color: Theme.border
    border.width: tog.value ? 0 : Theme.shape.border.width
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        width: 16; height: 16; radius: Theme.shape.radius.control
        y: 3
        x: tog.value ? tog.width - width - 3 : 3
        color: tog.value ? Theme.background : Theme.subtext
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            tog.toggled()
            tog.valueEdited(!tog.value)
        }
    }
}
