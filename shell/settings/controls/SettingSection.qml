import QtQuick
import "../../components"

import "../../services"

// Section header between groups of rows: a small tracked caption with a rule
// and, optionally, one line of context. Fold long intro prose into
// `description` instead of leaving a floating paragraph above the rows.
// While a search is active it hides itself when none of the rows that follow
// it (up to the next section) are visible.
Item {
    id: section
    property string icon: ""
    property string label: ""
    property string description: ""
    readonly property bool isSection: true
    width: parent.width
    implicitHeight: column.height + 14
    height: implicitHeight
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

    Column {
        id: column
        anchors {
            left: parent.left; right: parent.right; top: parent.top
            leftMargin: 14; rightMargin: 14; topMargin: 8
        }
        spacing: 3

        Item {
            width: parent.width
            height: 20

            Text {
                id: headIcon
                visible: section.icon !== ""
                text: section.icon
                color: Theme.accent
                font.pixelSize: Theme.font.size.normal
                font.family: Theme.font.mono
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: headLabel
                anchors {
                    left: headIcon.visible ? headIcon.right : parent.left
                    leftMargin: headIcon.visible ? 8 : 0
                    verticalCenter: parent.verticalCenter
                }
                text: section.label
                color: Theme.subtext
                font.pixelSize: Theme.font.size.small
                font.family: Theme.font.family
                font.weight: 700
                font.letterSpacing: 0.8
            }

            Rectangle {
                anchors {
                    left: headLabel.right; leftMargin: 10
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                height: 1
                color: Theme.border
                opacity: 0.5
            }
        }

        Text {
            width: parent.width
            visible: section.description !== ""
            text: section.description
            color: Theme.subtext
            font.pixelSize: Theme.font.size.small
            font.family: Theme.font.family
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }
}
