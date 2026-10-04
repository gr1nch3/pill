import QtQuick

import "../services"
import "../components"

OsdSlider {
    stateName: "volume"
    value: Audio.percent
    icon: "󰕾"
    iconMuted: "󰝟"
    fillColor: Theme.accent
    muted: Audio.muted

    onIconClicked: Audio.toggleMute()
    onWheelUp: Audio.adjust(5)
    onWheelDown: Audio.adjust(-5)
}
