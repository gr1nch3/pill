import QtQuick

Row {
    id: root

    property int value: 0
    property color fillColor: Theme.accent
    property string knobColor: ""
    property string icon: ""
    property bool showPercent: true
    property bool interactive: true

    signal valueChangedByUser(int value)
    signal iconClicked

    spacing: 10

    Text {
        id: iconLabel
        visible: root.icon !== ""
        text: root.icon
        font.pixelSize: Theme.font.size.xlarge
        font.family: Theme.font.mono
        color: Theme.text
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Rectangle {
        width: root.width - (root.icon !== "" ? 28 : 0) - (root.showPercent ? 40 : 0)
        height: 28
        radius: 14
        color: Theme.background
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        Rectangle {
            id: fillBar
            // Volume can exceed 100%; clamp the bar so it doesn't overflow.
            width: Math.max(14, Math.min(parent.width, parent.width * (root.value / 100)))
            height: parent.height
            radius: 14
            color: root.fillColor
            Behavior on width { NumberAnimation { duration: 100 } }
        }

        Rectangle {
            id: knob
            x: Math.min(fillBar.width - 12, parent.width - 24)
            y: 2; width: 24; height: 24; radius: 12
            color: root.knobColor || root.fillColor
            visible: root.knobColor !== ""
            Behavior on x { NumberAnimation { duration: 100 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: root.interactive

            function setValue(mouse) {
                var pct = Math.round((mouse.x / width) * 100)
                pct = Math.max(0, Math.min(100, pct))
                root.valueChangedByUser(pct)
            }

            onClicked: function(mouse) { setValue(mouse) }
            onPositionChanged: function(mouse) { if (pressed) setValue(mouse) }
        }
    }

    Text {
        visible: root.showPercent
        text: root.value + "%"
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        width: 30
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
    }
}
