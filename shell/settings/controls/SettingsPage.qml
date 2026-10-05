import QtQuick
import "../../components"

import "../../services"

// Base for every settings page: a blended page header (icon, title, one-line
// description — no card, so the panel background and its pattern run straight
// through it) plus visibility/sizing and the refresh-on-activation hook.
// SettingsWindow fills pageTitle/pageIcon/pageDesc from the page registry when
// it loads the page, so pages carry no nav metadata themselves.
Column {
    id: page
    property bool active: false
    property string pageIcon: ""
    property string pageTitle: ""
    property string pageDesc: ""
    // Normalized page actions, rendered right-aligned under the header:
    //   [{ label, icon?, accent?, danger?, busy?, visible?, onTrigger }]
    // The array is a binding, so referenced state (Network.connected, …)
    // re-evaluates it and buttons can appear/disappear with context.
    property var actions: []

    visible: active
    width: parent.width
    spacing: 4

    Component.onCompleted: if (active)
        page.refresh()
    onActiveChanged: {
        if (active)
            page.refresh();
        else
            page.closeDialogs();
    }

    function refresh() {
    }

    // Modal dialogs live inside the page; a page switch or the settings pane
    // closing must take them along, or the popup stays over the island.
    function closeDialogs() {
        for (var i = 0; i < page.data.length; i++) {
            var k = page.data[i];
            if (k && typeof k.close === "function" && typeof k.modal === "boolean" && k.opened === true)
                k.close();
        }
    }

    Connections {
        target: IslandState
        function onStateChanged() {
            if (IslandState.state !== "settings")
                page.closeDialogs();
        }
    }

    // ── page header ────────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: page.pageTitle !== "" ? 72 : 0
        visible: page.pageTitle !== ""

        Row {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: 10
            }
            spacing: 10

            Item {
                width: 34
                height: headerText.height

                Text {
                    anchors.centerIn: parent
                    text: page.pageIcon
                    visible: page.pageIcon !== ""
                    color: Theme.accent
                    font.pixelSize: 26
                    font.family: Theme.font.mono
                }
            }

            Column {
                id: headerText
                width: parent.width - 44
                spacing: 2

                Text {
                    width: parent.width
                    text: page.pageTitle
                    color: Theme.text
                    font.pixelSize: Theme.font.size.xlarge
                    font.family: Theme.font.family
                    font.weight: 800
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: page.pageDesc !== ""
                    text: page.pageDesc
                    color: Theme.subtext
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ── page actions (right-aligned, directly under the header) ────────────
    Item {
        width: parent.width
        height: page.actions.length > 0 ? 28 : 0
        visible: page.actions.length > 0

        Row {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            Repeater {
                model: page.actions

                delegate: SettingAction {
                    required property var modelData
                    visible: modelData.visible === undefined || modelData.visible === true
                    label: modelData.label !== undefined ? modelData.label : ""
                    icon: modelData.icon !== undefined ? modelData.icon : ""
                    accent: modelData.accent === true
                    danger: modelData.danger === true
                    busy: modelData.busy === true
                    interactive: modelData.interactive === undefined || modelData.interactive === true
                    onClicked: if (modelData.onTrigger !== undefined)
                        modelData.onTrigger()
                }
            }
        }
    }
}
