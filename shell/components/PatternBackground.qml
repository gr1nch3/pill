// Procedural background patterns, clipped to a surface shape.
// Pure QtQuick (no Theme/Quickshell imports) so the SDDM greeter can copy it
// verbatim (see PKGBUILD) — pass explicit colours there.
//
// Variants: none | dots | grid | diagonal | cross | chevron | noise.
// The shape vocabulary matches SurfaceShape: rounded | rect | parallelogram |
// trapezoid | hex, with the same cut formula as Themes.shapeCut.
import QtQuick 2.15

Canvas {
    id: root

    property string variant: "none"
    property real spacing: 18
    property color color: "#ffffff"
    property real strength: 0.08
    property string shape: "rounded"
    property real slant: 0.35
    property real radius: 0

    renderStrategy: Canvas.Threaded

    onVariantChanged: requestPaint()
    onSpacingChanged: requestPaint()
    onColorChanged: requestPaint()
    onStrengthChanged: requestPaint()
    onShapeChanged: requestPaint()
    onSlantChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    // Same clamp as Themes.shapeCut — keep the two in sync.
    readonly property real _cut: {
        if (shape !== "parallelogram" && shape !== "trapezoid" && shape !== "hex")
            return 0;
        return Math.min(height * slant, 40, width * 0.2);
    }

    function _clip(ctx, w, h) {
        var c = root._cut;
        ctx.beginPath();
        if (shape === "parallelogram") {
            ctx.moveTo(c, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w - c, h);
            ctx.lineTo(0, h);
        } else if (shape === "trapezoid") {
            ctx.moveTo(c, 0);
            ctx.lineTo(w - c, 0);
            ctx.lineTo(w, h);
            ctx.lineTo(0, h);
        } else if (shape === "hex") {
            ctx.moveTo(c, 0);
            ctx.lineTo(w - c, 0);
            ctx.lineTo(w, h / 2);
            ctx.lineTo(w - c, h);
            ctx.lineTo(c, h);
            ctx.lineTo(0, h / 2);
        } else {
            var r = shape === "rect" ? 0 : Math.max(0, Math.min(radius, w / 2, h / 2));
            if (r <= 0) {
                ctx.moveTo(0, 0);
                ctx.lineTo(w, 0);
                ctx.lineTo(w, h);
                ctx.lineTo(0, h);
            } else {
                ctx.moveTo(r, 0);
                ctx.lineTo(w - r, 0);
                ctx.arcTo(w, 0, w, r, r);
                ctx.lineTo(w, h - r);
                ctx.arcTo(w, h, w - r, h, r);
                ctx.lineTo(r, h);
                ctx.arcTo(0, h, 0, h - r, r);
                ctx.lineTo(0, r);
                ctx.arcTo(0, 0, r, 0, r);
            }
        }
        ctx.closePath();
        ctx.clip();
    }

    function _paint(ctx) {
        var w = root.width, h = root.height;
        ctx.clearRect(0, 0, w, h);
        if (root.variant === "none" || w <= 0 || h <= 0)
            return;
        var s = Math.max(8, root.spacing);
        var ink = Qt.rgba(root.color.r, root.color.g, root.color.b, root.strength);
        ctx.save();
        ctx.beginPath();
        root._clip(ctx, w, h);
        ctx.fillStyle = ink;
        ctx.strokeStyle = ink;
        ctx.lineWidth = 1;

        var x, y, i;
        if (root.variant === "dots") {
            for (y = s / 2; y < h; y += s)
                for (x = s / 2; x < w; x += s) {
                    ctx.beginPath();
                    ctx.arc(x, y, 1.6, 0, Math.PI * 2);
                    ctx.fill();
                }
        } else if (root.variant === "grid") {
            for (x = s; x < w; x += s) {
                ctx.beginPath();
                ctx.moveTo(x + 0.5, 0);
                ctx.lineTo(x + 0.5, h);
                ctx.stroke();
            }
            for (y = s; y < h; y += s) {
                ctx.beginPath();
                ctx.moveTo(0, y + 0.5);
                ctx.lineTo(w, y + 0.5);
                ctx.stroke();
            }
        } else if (root.variant === "diagonal") {
            for (i = -h; i < w + h; i += s) {
                ctx.beginPath();
                ctx.moveTo(i, 0);
                ctx.lineTo(i + h, h);
                ctx.stroke();
            }
        } else if (root.variant === "cross") {
            var r = Math.max(2, s * 0.16);
            for (y = s / 2; y < h; y += s)
                for (x = s / 2; x < w; x += s) {
                    ctx.beginPath();
                    ctx.moveTo(x - r, y);
                    ctx.lineTo(x + r, y);
                    ctx.moveTo(x, y - r);
                    ctx.lineTo(x, y + r);
                    ctx.stroke();
                }
        } else if (root.variant === "chevron") {
            var amp = s * 0.35;
            for (y = 0; y < h + amp; y += s) {
                ctx.beginPath();
                ctx.moveTo(-s, y);
                i = 0;
                for (x = -s; x < w + s; x += s / 2) {
                    ctx.lineTo(x, y + (i % 2 === 0 ? -amp : amp));
                    i++;
                }
                ctx.stroke();
            }
        } else if (root.variant === "noise") {
            // Deterministic speckles: same pattern on every repaint.
            root._seed = 1103515245;
            var count = Math.floor((w * h) / (s * s)) * 2;
            for (i = 0; i < count; i++) {
                ctx.beginPath();
                ctx.arc(root._rnd() * w, root._rnd() * h, 0.6 + root._rnd() * 1.2, 0, Math.PI * 2);
                ctx.fill();
            }
        }
        ctx.restore();
    }

    property int _seed: 1103515245

    function _rnd() {
        _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
        return _seed / 0x7fffffff;
    }

    onPaint: root._paint(getContext("2d"))
}
