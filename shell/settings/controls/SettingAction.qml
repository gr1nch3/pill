import QtQuick
import "../../components"

SurfaceShape {
    id: btn
    shape: Theme.shape.style
    slant: Theme.shape.slant
    property string label: ""
    property bool accent: false
    property bool danger: false
    property bool busy: false
    // Named interactive, not enabled: Item.enabled is final.
    property bool interactive: true
    signal clicked

    width: btnLabel.implicitWidth + 22
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

    Text {
        id: btnLabel
        anchors.centerIn: parent
        text: btn.busy ? "…" : btn.label
        color: (btn.danger || btn.accent || btnMouse.containsMouse) && btn.interactive ? Theme.background : Theme.text
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        font.weight: 600
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
