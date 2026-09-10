import QtQuick

import "../services"
import "../components"

OsdSlider {
    stateName: "volume"
    value: Volume.percent
    icon: "󰕾"
    iconMuted: "󰝟"
    fillColor: Theme.accent
    muted: Volume.muted

    onIconClicked: Volume.toggleMute()
    onWheelUp: Volume.adjust(5)
    onWheelDown: Volume.adjust(-5)
}
