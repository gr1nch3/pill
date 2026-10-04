import QtQuick
import "../components"
import "../services"

// Eye with Bubbles' theme/config defaults applied. Views set geometry + mood
// (and override `visible` only when the face is conditional).
Eye {
    moods: Theme.eyeMoods
    variant: Config.eyeVariant
    visible: Config.eyesEnabled
}
