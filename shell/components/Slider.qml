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

    // While dragging, the bar follows the pointer directly and the service is
    // told at most once per THROTTLE_MS (leading + trailing) instead of every
    // pointer event: pactl spawns and list rebuilds per pixel were the old
    // cost. One final value is sent on release.
    readonly property int _throttleMs: 80
    property int _dragValue: -1
    property int _lastEmitted: -1
    readonly property bool _dragging: _dragValue >= 0
    readonly property int shownValue: _dragging ? _dragValue : value

    function _schedule(pct) {
        _dragValue = pct
        if (!emitTimer.running) {
            _lastEmitted = pct
            valueChangedByUser(pct)
            emitTimer.start()
        }
    }

    function _release() {
        emitTimer.stop()
        if (_dragging && _dragValue !== _lastEmitted)
            valueChangedByUser(_dragValue)
        _dragValue = -1
        _lastEmitted = -1
    }

    Timer {
        id: emitTimer
        interval: root._throttleMs
        repeat: true
        onTriggered: {
            if (root._dragging && root._dragValue !== root._lastEmitted) {
                root._lastEmitted = root._dragValue
                root.valueChangedByUser(root._dragValue)
            }
        }
    }

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

    SurfaceShape {
        id: track
        shape: Theme.shape.style
        slant: Theme.shape.slant
        width: root.width - (root.icon !== "" ? 28 : 0) - (root.showPercent ? 40 : 0)
        height: 28
        radius: Theme.shape.radius.cardLarge
        color: Theme.background
        anchors.verticalCenter: parent.verticalCenter

        readonly property real minFill: (Theme.shape.style === "rounded" || Theme.shape.style === "rect")
            ? 14
            : height * Theme.shape.slant * 2 + 4

        SurfaceShape {
            id: fillBar
            shape: Theme.shape.style
            slant: Theme.shape.slant
            // Volume can exceed 100%; clamp the bar so it doesn't overflow.
            width: Math.max(track.minFill, Math.min(parent.width, parent.width * (root.shownValue / 100)))
            height: parent.height
            radius: Theme.shape.radius.cardLarge
            color: root.fillColor
            Behavior on width { enabled: !root._dragging; NumberAnimation { duration: Theme.motion.hover } }
        }

        Rectangle {
            id: knob
            x: Math.min(fillBar.width - 12, parent.width - 24)
            y: 2; width: 24; height: 24; radius: Theme.shape.radius.card
            color: root.knobColor || root.fillColor
            visible: root.knobColor !== ""
            Behavior on x { NumberAnimation { duration: Theme.motion.hover } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: root.interactive

            function setValue(mouse) {
                var pct = Math.round((mouse.x / width) * 100)
                pct = Math.max(0, Math.min(100, pct))
                root._schedule(pct)
            }

            // press + move + release: a click still emits once on press and the
            // release sends the final value; no onClicked duplicate.
            onPressed: function(mouse) { setValue(mouse) }
            onPositionChanged: function(mouse) { if (pressed) setValue(mouse) }
            onReleased: root._release()
            onCanceled: root._release()
        }
    }

    Text {
        visible: root.showPercent
        text: root.shownValue + "%"
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        width: 30
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
    }
}
