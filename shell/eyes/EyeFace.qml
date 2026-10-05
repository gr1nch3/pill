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
        function onStartled() { face.react() }
        function onBlinks() { face.blink() }
        function onGlanced() { face.glance(EyeReactions.glanceDir) }
    }
}
