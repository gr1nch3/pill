import QtQuick

// Base for every settings page: owns visibility/sizing and calls refresh()
// on activation. Pages override refresh() when they need one.
Column {
    id: page
    property bool active: false
    visible: active
    width: parent.width
    spacing: 4

    Component.onCompleted: if (active) page.refresh()
    onActiveChanged: if (active) page.refresh()

    function refresh() {}
}
