// Bar/hot-zone surface: top-edge hover reveal, auto-hide, pin.
// Owns barVisible + its timers; shell.qml binds the pill to barVisible
// and pokes pauseHide()/resumeHide() from the pill's own hover handlers.

import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell

import "../services"
import "../components"

WlrLayershell {
    id: root

    property bool pinned: Config.pinned
    property bool barVisible: true
    // Fed from IslandPill.containsMouse so hideTimer respects pill hover too.
    property bool pillHover: false

    function pauseHide() {
        hideTimer.stop();
        barVisible = true;
    }
    function resumeHide() {
        hideTimer.start();
    }

    onPinnedChanged: if (pinned) {
        hideTimer.stop();
        barVisible = true;
    }
    onBarVisibleChanged: if (pinned && !barVisible)
        barVisible = true

    anchors.top: Config.position === "top"
    anchors.bottom: Config.position === "bottom"
    implicitWidth: Screen.width
    implicitHeight: 4
    color: "transparent"
    exclusiveZone: 0
    layer: WlrLayer.Top
    keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    MouseArea {
        id: hotZoneArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            hideTimer.stop();
            showTimer.start();
        }
        onExited: hideTimer.start()
        onPositionChanged: {
            hideTimer.stop();
            if (!root.barVisible)
                showTimer.start();
        }
    }

    Timer {
        id: hideTimer
        interval: Config.autoHideDelay
        onTriggered: {
            if (IslandState.active)
                return;
            if (!hotZoneArea.containsMouse && !root.pillHover)
                root.barVisible = false;
        }
    }

    Timer {
        id: showTimer
        interval: Config.showDelay
        onTriggered: root.barVisible = true
    }

    Connections {
        target: IslandState
        function onPillExpandedChanged() {
            if (IslandState.pillExpanded)
                root.pauseHide();
        }
        function onActiveChanged() {
            if (!IslandState.active)
                hideTimer.start();
        }
    }
}
