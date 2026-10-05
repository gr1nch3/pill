import QtQuick

import "../components"
import "../services"
import "PageMatch.js" as PageMatch

// The settings nav rail: task-grouped sections, collapsible headers and a
// filter-aware item list. The window owns the page state; this only reports
// picks and folds itself when a search is live.
Item {
    id: root

    property var sections: []
    property string currentPage: ""
    signal pagePicked(string id)

    // ── Collapsible sections ───────────────────────────────────────────────
    property var collapsedSections: ({})

    function isSectionOpen(name) {
        // A search always unfolds: hiding a match behind a fold lies.
        return SettingsSearch.text !== "" || collapsedSections[name] !== true;
    }

    function toggleSection(name) {
        var next = {};
        for (var k in collapsedSections)
            next[k] = collapsedSections[k];
        next[name] = !next[name];
        collapsedSections = next;
    }

    Flickable {
        id: sidebarFlick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: sidebarColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: sidebarColumn
            width: sidebarFlick.width
            spacing: 2

            Item {
                width: parent.width
                height: 60
                visible: !PageMatch.anyMatches(root.sections, SettingsSearch.text)

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    text: "No settings match\nthat search"
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: root.sections

                delegate: Column {
                    id: navSection
                    required property var modelData
                    width: sidebarColumn.width
                    spacing: 1
                    visible: PageMatch.sectionMatches(navSection.modelData, SettingsSearch.text)

                    readonly property bool activeGroup: {
                        for (var i = 0; i < navSection.modelData.pages.length; i++)
                            if (navSection.modelData.pages[i].id === root.currentPage)
                                return true;
                        return false;
                    }

                    readonly property bool folded: !root.isSectionOpen(navSection.modelData.section)

                    // ── Section header (click to fold) ──────────────
                    Item {
                        id: navHead
                        width: parent.width
                        height: 30

                        Row {
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 7

                            Text {
                                text: navSection.modelData.icon
                                visible: text !== ""
                                color: navSection.activeGroup ? Theme.accent : (headMouse.containsMouse ? Theme.text : Theme.subtext)
                                font.pixelSize: Theme.font.size.small
                                font.family: Theme.font.mono
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.motion.hover
                                    }
                                }
                            }

                            Text {
                                text: navSection.modelData.section.toUpperCase()
                                color: (navSection.activeGroup || headMouse.containsMouse) ? Theme.text : Theme.subtext
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.family
                                font.weight: 700
                                font.letterSpacing: 0.7
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.motion.hover
                                    }
                                }
                            }
                        }

                        Text {
                            anchors {
                                right: parent.right
                                rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            visible: navSection.folded
                            text: navSection.modelData.pages.length
                            color: headMouse.containsMouse ? Theme.text : Theme.subtext
                            font.pixelSize: Theme.font.size.caption
                            font.family: Theme.font.family
                            font.weight: 700
                        }

                        MouseArea {
                            id: headMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleSection(navSection.modelData.section)
                        }
                    }

                    Repeater {
                        model: navSection.folded ? [] : navSection.modelData.pages

                        delegate: Rectangle {
                            id: navItem
                            required property var modelData
                            visible: PageMatch.matches(navItem.modelData, SettingsSearch.text) && !navSection.folded
                            width: sidebarColumn.width
                            height: visible ? 34 : 0
                            radius: Theme.shape.radius.row
                            color: root.currentPage === navItem.modelData.id ? Theme.accent : (navMouse.containsMouse ? Theme.surfaceHover : "transparent")
                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.motion.hover
                                }
                            }

                            Row {
                                anchors {
                                    left: parent.left
                                    leftMargin: 12
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 8

                                Text {
                                    width: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    text: navItem.modelData.icon
                                    color: root.currentPage === navItem.modelData.id ? Theme.background : Theme.text
                                    font.pixelSize: Theme.font.size.large
                                    font.family: Theme.font.mono
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: navItem.width - 12 - 18 - 8 - 10
                                    text: navItem.modelData.label
                                    color: root.currentPage === navItem.modelData.id ? Theme.background : Theme.text
                                    font.pixelSize: Theme.font.size.normal
                                    font.family: Theme.font.family
                                    font.weight: root.currentPage === navItem.modelData.id ? 700 : 500
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pagePicked(navItem.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // Sidebar scroll affordance
    Rectangle {
        x: root.width - 5
        width: 3
        radius: 1.5
        color: Theme.subtext
        opacity: 0.4
        visible: sidebarFlick.contentHeight > sidebarFlick.height
        height: Math.max(24, sidebarFlick.height * sidebarFlick.height / sidebarFlick.contentHeight)
        y: sidebarFlick.contentHeight > sidebarFlick.height ? (sidebarFlick.contentY / (sidebarFlick.contentHeight - sidebarFlick.height)) * (sidebarFlick.height - height) : 0
    }
}
