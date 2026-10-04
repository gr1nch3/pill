import QtQuick
import "../../components"

// Exclusive options row. Options may be plain strings or { value, label }.
// Value-first callers bind `currentValue` and handle `valueSelected`;
// `currentIndex`/`selected` are the old names, kept for existing pages.
Row {
    id: chips
    property var options: []
    property var currentValue: undefined
    property int currentIndex: 0
    signal valueSelected(var value)
    signal selected(int index)
    spacing: 4

    function _label(opt) {
        return typeof opt === "string" ? opt : opt.label
    }

    function _value(opt) {
        return typeof opt === "string" ? opt : opt.value
    }

    function _isCurrent(opt, index) {
        if (chips.currentValue !== undefined) return chips._value(opt) === chips.currentValue
        return index === chips.currentIndex
    }

    Repeater {
        model: chips.options
        delegate: SurfaceShape {
            required property var modelData
            required property int index
            shape: Theme.shape.style
            slant: Theme.shape.slant
            width: chipLabel.implicitWidth + 20
            height: 26
            radius: Theme.shape.radius.control
            color: chips._isCurrent(modelData, index)
                ? Theme.accent
                : (chipMouse.containsMouse ? Theme.surfaceHover : Theme.background)
            Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

            Text {
                id: chipLabel
                anchors.centerIn: parent
                text: chips._label(modelData)
                color: chips._isCurrent(modelData, index) ? Theme.background : Theme.text
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
                font.weight: 500
            }

            MouseArea {
                id: chipMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    chips.selected(index)
                    chips.valueSelected(chips._value(modelData))
                }
            }
        }
    }
}
