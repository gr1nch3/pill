import QtQuick
import QtQuick.Shapes

import "../utils/Themes.js" as Themes

// Theme-driven surface geometry. "rounded" (default) uses the cheap Rectangle
// path; polygon styles draw with Shape so content stays upright. The theme's
// shape.style picks the geometry, shape.slant controls the cut angle.
Item {
    id: root

    property string shape: "rounded"   // rounded | rect | parallelogram | trapezoid | hex
    property real slant: 0.35          // cut ratio (of height) for polygons
    property real radius: 0
    property color color: "transparent"
    property color borderColor: "transparent"
    property real borderWidth: 0

    readonly property bool _poly: shape === "parallelogram" || shape === "trapezoid" || shape === "hex"
    readonly property real _cut: Themes.shapeCut(root.shape, root.slant, width, height)

    // Vertex table per style; ShapePath walks it with a fixed number of lines.
    readonly property var _v: {
        var w = root.width, h = root.height, c = root._cut;
        if (root.shape === "parallelogram")
            return [[c, 0], [w, 0], [w - c, h], [0, h]];
        if (root.shape === "trapezoid")
            return [[c, 0], [w - c, 0], [w, h], [0, h]];
        if (root.shape === "hex")
            return [[c, 0], [w - c, 0], [w, h / 2], [w - c, h], [c, h], [0, h / 2]];
        return [];
    }

    function _vx(i) {
        if (root._v.length === 0)
            return 0;
        return root._v[Math.min(i, root._v.length - 1)][0];
    }

    function _vy(i) {
        if (root._v.length === 0)
            return 0;
        return root._v[Math.min(i, root._v.length - 1)][1];
    }

    Rectangle {
        visible: !root._poly
        anchors.fill: parent
        radius: root.shape === "rect" ? 0 : root.radius
        color: root.color
        border.color: root.borderColor
        border.width: root.borderWidth
    }

    Shape {
        visible: root._poly
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
            strokeWidth: root.borderWidth

            startX: root._vx(0)
            startY: root._vy(0)
            PathLine {
                x: root._vx(1)
                y: root._vy(1)
            }
            PathLine {
                x: root._vx(2)
                y: root._vy(2)
            }
            PathLine {
                x: root._vx(3)
                y: root._vy(3)
            }
            PathLine {
                x: root._vx(4)
                y: root._vy(4)
            }
            PathLine {
                x: root._vx(5)
                y: root._vy(5)
            }
        }
    }
}
