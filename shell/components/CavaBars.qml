import QtQuick

Canvas {
    id: root

    property var bars: []
    property int barCount: 4
    property int barWidth: 3
    property int barGap: 1
    property color barColor: Theme.accent

    onBarsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onBarColorChanged: requestPaint()
    onBarWidthChanged: requestPaint()
    onBarGapChanged: requestPaint()
    onBarCountChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var data = bars;
        if (data.length === 0)
            return;
        var count = Math.min(data.length, barCount);
        var offsetX = (width - (count * barWidth + (count - 1) * barGap)) / 2;
        for (var i = 0; i < count; i++) {
            var val = data[i] / 100;
            var barH = Math.max(2, val * height);
            var x = offsetX + i * (barWidth + barGap);
            var y = height - barH;
            ctx.beginPath();
            ctx.rect(x, y, barWidth, barH);
            ctx.fillStyle = barColor;
            ctx.globalAlpha = 0.4 + val * 0.6;
            ctx.fill();
            ctx.globalAlpha = 1.0;
        }
    }
}
