import QtQuick
import "../../components"

import "../../services"

// Section header. While a search is active it hides itself when none of the
// rows that follow it (up to the next section) are visible.
Item {
    id: section
    property string icon: ""
    property string label: ""
    readonly property bool isSection: true
    width: parent.width
    height: 38
    visible: SettingsSearch.text === "" || section.hasVisibleRows

    readonly property bool hasVisibleRows: {
        if (!section.parent) return false
        var kids = section.parent.children
        var start = -1
        for (var i = 0; i < kids.length; i++)
            if (kids[i] === section) { start = i; break }
        if (start < 0) return false
        for (var j = start + 1; j < kids.length; j++) {
            var k = kids[j]
            if (k.isSection === true) break
            if (k.visible === true) return true
        }
        return false
    }

    Row {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 8

        Text {
            text: section.icon
            visible: section.icon !== ""
            color: Theme.subtext
            font.pixelSize: Theme.font.size.normal
            font.family: Theme.font.mono
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: section.label
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            font.weight: 700
            font.letterSpacing: 0.6
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
