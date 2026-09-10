import QtQuick

import "../services"
import "../components"
import "../utils"

OsdSlider {
    stateName: "brightness"
    value: Brightness.percent
    icon: Brightness.percent < 20 ? Icons.brightnessLow : Icons.brightness
    fillColor: Theme.accentAlt
    fillColorMuted: Theme.subtext
    muted: Brightness.percent === 0

    onWheelUp: Brightness.adjust(5)
    onWheelDown: Brightness.adjust(-5)
}
