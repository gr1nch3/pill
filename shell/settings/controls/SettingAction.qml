import QtQuick
import "../../components"

// Pill button. `icon` is an optional leading glyph; `label` sits beside it, or
// alone when there is no icon. Named `interactive`, not enabled: Item.enabled
// is final.
SurfaceShape {
    id: btn
    shape: Theme.shape.style
    slant: Theme.shape.slant
    property string label: ""
    property string icon: ""
    property bool accent: false
    property bool danger: false
    property bool busy: false
    property bool interactive: true
    signal clicked

    readonly property color _ink: (danger || accent || btnMouse.containsMouse) && interactive
        ? Theme.background : Theme.text
    readonly property real _contentW: (icon !== "" ? btnIcon.implicitWidth + 6 : 0) + btnLabel.implicitWidth

    width: _contentW + 22
    height: 26
    radius: Theme.shape.radius.control
    opacity: btn.interactive ? 1 : 0.45
    color: {
        if (!btn.interactive) return Theme.background
        if (btn.busy) return Theme.surfaceHover
        if (btn.danger) return btnMouse.containsMouse ? Qt.lighter(Theme.danger, 1.2) : Theme.danger
        if (btn.accent) return Theme.accent
        return btnMouse.containsMouse ? Theme.accent : Theme.surfaceHover
    }
    Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

    Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: btnIcon
            visible: btn.icon !== ""
            text: btn.icon
            color: btn._ink
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.mono
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: btnLabel
            text: btn.busy ? "…" : btn.label
            color: btn._ink
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            font.weight: 600
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: btn.interactive && !btn.busy
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
