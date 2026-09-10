import QtQuick

Canvas {
    id: root

    property real value: 0
    property color arcColor: Theme.accent
    property color trackColor: Theme.highlight
    property real lineWidth: 2.5
    property real startAngle: -Math.PI / 2

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        var cx = width / 2, cy = height / 2, r = width / 2 - 2

        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.strokeStyle = trackColor
        ctx.lineWidth = lineWidth
        ctx.stroke()

        ctx.beginPath()
        ctx.arc(cx, cy, r, startAngle, startAngle + (Math.PI * 2 * value))
        ctx.strokeStyle = arcColor
        ctx.lineWidth = lineWidth
        ctx.lineCap = "round"
        ctx.stroke()
    }

    onValueChanged: requestPaint()
}
