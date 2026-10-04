import QtQuick

// Base for every island state: owns the fade/visibility/escape chrome and
// declares the pane's own size + pill policy. IslandPill resolves the active
// pane by stateName instead of switching on state strings.
Item {
    id: pane

    property string stateName: ""
    // Extra states this pane also serves (DeviceSelect: connectivity + audiodevice).
    property var extraStates: []
    // Large panes opt into the procedural background pattern (Config.patternStyle).
    property bool pattern: false
    property bool centered: false
    property string radiusMode: "panel"     // "pill" | "panel" | "none" | "notifications"
    property bool keyboardFocus: false
    property real preferredWidth: -1        // -1 = dispatcher fallback
    property real preferredHeight: -1
    property int fadeDuration: 200

    readonly property bool active: handles(IslandState.state)

    function handles(name) {
        return name === stateName || extraStates.indexOf(name) !== -1
    }

    opacity: active ? 1 : 0
    visible: opacity > 0
    focus: visible
    Behavior on opacity { NumberAnimation { duration: pane.fadeDuration; easing.type: Easing.OutCubic } }
    Keys.onEscapePressed: IslandState.closeToIdle()
}
