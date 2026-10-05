import QtQuick

import "../../components"
import "../../services"

// One full-width settings row: icon, title, description, and a right-aligned
// control slot (declare children directly). Rows that sit next to each other
// paint one continuous card: each row rounds its corners only at the group
// edges and overdraws the page column's gap, so a run of rows reads as one
// sheet parted by hairlines. A section header, note, preview or any other
// block between rows ends the group.
//
// Hides itself while a settings search doesn't match title/subtitle/keywords,
// or while visibleWhen is false.
Rectangle {
    id: row
    default property alias action: slotRow.data
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    // Extra search vocabulary the copy never uses (synonyms, abbreviations).
    property string keywords: ""
    property bool visibleWhen: true
    readonly property bool isSettingRow: true

    readonly property bool matchesSearch: SettingsSearch.text === "" || (title + " " + subtitle + " " + keywords).toLowerCase().indexOf(SettingsSearch.text.toLowerCase()) !== -1

    // Each side swallows half of the page column's spacing so grouped rows
    // meet edge to edge.
    readonly property int gap: 2

    function _indexOf(kids, item) {
        for (var i = 0; i < kids.length; i++)
            if (kids[i] === item)
                return i;
        return -1;
    }

    // Nearest visible sibling that is itself a row; null when the neighbour is
    // a section/note/preview (or when there is none). Hidden rows and empty
    // Repeater handles don't break a run.
    function _adjacentRow(step) {
        if (!row.parent)
            return null;
        var kids = row.parent.children;
        var i = row._indexOf(kids, row);
        if (i < 0)
            return null;
        i += step;
        while (i >= 0 && i < kids.length) {
            var k = kids[i];
            if (k && k.visible !== false && k !== row) {
                if (k.isSettingRow === true)
                    return k;
                // Repeater handles manage sibling delegates; step past them.
                if (k.count !== undefined && k.delegate !== undefined) {
                    i += step;
                    continue;
                }
                return null;
            }
            i += step;
        }
        return null;
    }

    readonly property var _prevRow: _adjacentRow(-1)
    readonly property var _nextRow: _adjacentRow(1)
    readonly property bool groupStart: _prevRow === null
    readonly property bool groupEnd: _nextRow === null

    width: parent.width
    height: subtitle !== "" ? 58 : 44
    color: "transparent"
    visible: matchesSearch && visibleWhen

    // Group card. Top/bottom overdraw closes the page column's gaps; per-corner
    // radii keep every group's outer silhouette rounded.
    Rectangle {
        id: bg
        readonly property int cr: Theme.shape.radius.row
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: row.groupStart ? 0 : -row.gap
            bottom: parent.bottom
            bottomMargin: row.groupEnd ? 0 : -row.gap
        }
        topLeftRadius: row.groupStart ? cr : 0
        topRightRadius: row.groupStart ? cr : 0
        bottomLeftRadius: row.groupEnd ? cr : 0
        bottomRightRadius: row.groupEnd ? cr : 0
        color: rowMouse.containsMouse ? Theme.surfaceHover : Theme.surface
        Behavior on color {
            ColorAnimation {
                duration: Theme.motion.hover
            }
        }
    }

    // Parting hairline inside a group.
    Rectangle {
        visible: !row.groupStart
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: 14
            rightMargin: 14
            top: bg.top
        }
        height: 1
        color: Theme.border
        opacity: 0.7
    }

    Rectangle {
        id: iconTile
        visible: row.icon !== ""
        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        width: 30
        height: 30
        radius: Theme.shape.radius.control
        color: rowMouse.containsMouse ? Theme.highlight : Theme.background
        Behavior on color {
            ColorAnimation {
                duration: Theme.motion.hover
            }
        }

        Text {
            anchors.centerIn: parent
            text: row.icon
            color: Theme.accent
            font.pixelSize: Theme.font.size.large
            font.family: Theme.font.mono
        }
    }

    Column {
        anchors {
            left: iconTile.visible ? iconTile.right : parent.left
            leftMargin: iconTile.visible ? 10 : 14
            right: slotHost.left
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 1

        Text {
            width: parent.width
            text: row.title
            color: Theme.text
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.family
            font.weight: 600
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: row.subtitle
            visible: row.subtitle !== ""
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            elide: Text.ElideRight
        }
    }

    Item {
        id: slotHost
        anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: slotRow.implicitWidth
        implicitHeight: slotRow.implicitHeight

        Row {
            id: slotRow
            anchors.centerIn: parent
            spacing: 8
        }
    }

    MouseArea {
        id: rowMouse
        z: -1
        anchors.fill: parent
        hoverEnabled: true
    }
}
