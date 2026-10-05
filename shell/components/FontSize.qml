import QtQuick

// Typed font-size scale (Theme.font.size). A declared component so tooling
// (qmllint) can resolve Theme.font.size.<name> members; a plain nested
// QtObject is invisible to static checking.
QtObject {
    property real scale: 1
    property int caption: Math.round(9 * scale)
    property int small: Math.round(11 * scale)
    property int normal: Math.round(13 * scale)
    property int large: Math.round(16 * scale)
    property int xlarge: Math.round(20 * scale)
}
