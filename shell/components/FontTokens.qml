import QtQuick

// Typed font tokens (Theme.font): declared component instead of a nested
// QtObject so qmllint can resolve font.family/mono/size at call sites.
QtObject {
    property string family: ""
    property string mono: ""
    property FontSize size: FontSize {}
}
