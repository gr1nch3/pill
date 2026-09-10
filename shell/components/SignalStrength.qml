import QtQuick

Row {
    id: root

    property int value: 0
    spacing: 1

    Repeater {
        model: 4
        Rectangle {
            width: 3
            height: 4 + index * 3
            radius: 1
            anchors.bottom: parent.bottom
            color: root.value > index * 25 ? Theme.accent : Theme.border
        }
    }
}
