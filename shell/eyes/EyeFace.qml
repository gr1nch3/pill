import QtQuick
import "../components"
import "../services"

// Eye with Bubbles' theme/config defaults applied. Views set geometry + the
// contextual `baseMood` (and override `visible` only when the face is
// conditional); EyeReactions lay a short-lived mood/motion over it, idle time
// brings out the sleepy variant, and hovering the pill makes the pupils track
// the pointer.
Eye {
    id: face

    property string baseMood: "idle"

    // QML's `visible` is local to the item, so without this an eye on a
    // latched settings page or an inactive island pane keeps drifting and
    // blinking forever. AND the nearest page's `active` (SettingsPage) with
    // the nearest state pane's `active` (StatePane, identified by stateName);
    // standalone faces (greeter, lockscreen surface) find no pane and run.
    animationsActive: {
        var p = face.parent
        var activeKey = "active"
        var paneKey = "stateName"
        var pageActive = true
        var paneActive = true
        while (p) {
            // variable keys: the owners are dynamic ancestors (StatePane /
            // SettingsPage), not part of EyeFace's declared type
            if (p[activeKey] !== undefined) {
                if (p[paneKey] !== undefined) paneActive = paneActive && p[activeKey]
                else pageActive = pageActive && p[activeKey]
            }
            p = p.parent
        }
        return pageActive && paneActive
    }

    moods: Theme.eyeMoods
    variant: EyeReactions.sleeping ? "sleepy" : Config.eyeVariant
    visible: Config.eyesEnabled
    mood: EyeReactions.mood !== "" ? EyeReactions.mood : baseMood
    trackCursor: IslandState.pointerOver && IslandState.pointerMoving && IslandState.hoverScene.x >= 0
    target: trackCursor
        ? face.mapFromItem(null, IslandState.hoverScene.x, IslandState.hoverScene.y)
        : Qt.point(-1, -1)

    Connections {
        target: EyeReactions
        // the reaction counters are properties; their *Changed signals are
        // what actually fire (onStartled would never run)
        function onStartledChanged() { face.react() }
        function onBlinksChanged() { face.blink() }
        function onGlancedChanged() { face.glance(EyeReactions.glanceDir) }
    }
}
