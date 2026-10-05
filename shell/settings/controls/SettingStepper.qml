import QtQuick
import "../../components"

// Value-first stepper: clamps to [from, to] and emits the requested value.
// `text`/`plus`/`minus` are the old names, kept for existing pages.
Row {
    id: stepper
    property real value: 0
    property real from: -Infinity
    property real to: Infinity
    property real step: 1
    property var format: "%1"
    property string text: ""
    signal valueEdited(real value)
    signal plus
    signal minus
    spacing: 4

    readonly property string displayText: {
        if (stepper.text !== "")
            return stepper.text;
        if (typeof stepper.format === "function")
            return stepper.format(stepper.value);
        return String(stepper.format).replace("%1", stepper.value);
    }

    function _emit(delta) {
        var v = Math.max(stepper.from, Math.min(stepper.to, stepper.value + delta));
        stepper.valueEdited(v);
    }

    Text {
        text: stepper.displayText
        color: Theme.text
        font.pixelSize: Theme.font.size.normal
        font.family: Theme.font.family
        width: 52
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        width: 26
        height: 22
        radius: Theme.shape.radius.small
        color: plusMouse.containsMouse ? Theme.accent : Theme.surfaceHover
        Behavior on color {
            ColorAnimation {
                duration: Theme.motion.fast
            }
        }
        anchors.verticalCenter: parent.verticalCenter

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
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                stepper.plus();
                stepper._emit(stepper.step);
            }
        }
    }

    Rectangle {
        width: 26
        height: 22
        radius: Theme.shape.radius.small
        color: minusMouse.containsMouse ? Theme.accent : Theme.surfaceHover
        Behavior on color {
            ColorAnimation {
                duration: Theme.motion.fast
            }
        }
        anchors.verticalCenter: parent.verticalCenter

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
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                stepper.minus();
                stepper._emit(-stepper.step);
            }
        }
    }
}
