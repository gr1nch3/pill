// Whole-system settings workspace: fixed size, sectioned scrollable sidebar,
// page content scrolls independently. Option A navigation — one sidebar,
// complex pages drill down inside the content area.
import QtQuick
import Quickshell

import "../services"
import "../components"
import "../eyes"
import "pages"

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 16

    readonly property real panelWidth: 900
    readonly property real contentHeight: 620

    // Empty until the tool registry has probed, so the first page's
    // refresh-on-active sees real capabilities.
    property string page: ""
    readonly property string initialPage: "bar"

    Connections {
        target: Integrations
        function onReadyChanged() { if (root.page === "") root.page = root.initialPage }
    }

    Component.onCompleted: if (Integrations.ready && root.page === "") root.page = root.initialPage

    // One registry row per page: nav metadata + the component to load.
    // Sidebar sections and search derive from it; adding a page is one row
    // plus one Component line.
    readonly property var pages: [
        { id: "wifi", section: "Connections", label: "Wi-Fi", icon: "󰖩", keywords: "wlan wireless network", component: wifiComp },
        { id: "bluetooth", section: "Connections", label: "Bluetooth", icon: "󰂯", keywords: "bt devices pair", component: bluetoothComp },
        { id: "network", section: "Connections", label: "Ethernet & VPN", icon: "󰈀", keywords: "wired vpn profile nmcli", component: networkComp },
        { id: "displays", section: "Desktop", label: "Displays", icon: "󰍹", keywords: "monitor resolution scale refresh", component: displaysComp },
        { id: "input", section: "Desktop", label: "Input", icon: "󰌌", keywords: "keyboard mouse touchpad layout", component: inputComp },
        { id: "hyprland", section: "Desktop", label: "Hyprland", icon: "󰣖", keywords: "gaps decoration blur animations", component: hyprlandComp },
        { id: "shortcuts", section: "Desktop", label: "Keyboard Shortcuts", icon: "󰘮", keywords: "binds keybinds hyprland", component: shortcutsComp },
        { id: "sound", section: "System", label: "Sound", icon: "󰕾", keywords: "audio volume output input mic", component: soundComp },
        { id: "power", section: "System", label: "Power", icon: "󰐥", keywords: "battery profile suspend idle", component: powerComp },
        { id: "datetime", section: "System", label: "Date & Time", icon: "󰅐", keywords: "clock timezone ntp", component: datetimeComp },
        { id: "region", section: "System", label: "Region & Language", icon: "󰗊", keywords: "locale language keymap", component: regionComp },
        { id: "users", section: "System", label: "Users", icon: "󰀎", keywords: "accounts avatar name password", component: usersComp },
        { id: "defaults", section: "System", label: "Default Apps", icon: "󰈙", keywords: "browser mail mime associations", component: defaultsComp },
        { id: "theme", section: "Appearance", label: "Theme", icon: "󰏘", keywords: "colors palette user themes", component: themeComp },
        { id: "wallpaper", section: "Appearance", label: "Wallpaper", icon: "󰋩", keywords: "background image", component: wallpaperComp },
        { id: "backgrounds", section: "Appearance", label: "Backgrounds", icon: "󰏘", keywords: "pattern dots grid lock sign-in greeter sddm", component: backgroundsComp },
        { id: "typography", section: "Appearance", label: "Typography", icon: "󰎆", keywords: "font scale text", component: typographyComp },
        { id: "cursor", section: "Appearance", label: "Cursor & Icons", icon: "󰆿", keywords: "gtk icon theme pointer", component: cursorComp },
        { id: "fastfetch", section: "Appearance", label: "Fastfetch", icon: "󰄨", keywords: "fetch system info ascii logo theme terminal", component: fastfetchComp },
        { id: "bar", section: "Shell", label: "Bar & Eyes", icon: "󰈈", keywords: "pill position pin eyes", component: barComp },
        { id: "behaviour", section: "Shell", label: "Behaviour", icon: "󰒓", keywords: "auto hide osd delay", component: behaviourComp },
        { id: "notifications", section: "Shell", label: "Notifications", icon: "󰂚", keywords: "popups dnd sounds timeout", component: notificationsComp },
        { id: "integrations", section: "Shell", label: "Integrations", icon: "󱁤", keywords: "tools gtk qt retint wallust", component: integrationsComp },
        { id: "advanced", section: "Shell", label: "Advanced", icon: "󰉋", keywords: "folders paths", component: advancedComp },
        { id: "about", section: "About", label: "About", icon: "󰋜", keywords: "system info version session", component: aboutComp },
    ]

    readonly property var sectionIcons: ({
        "Connections": "󰖩",
        "Desktop": "󰍹",
        "System": "󰌢",
        "Appearance": "󰏘",
        "Shell": "󰒓",
        "About": "󰋜"
    })

    readonly property var navigation: {
        var sections = []
        for (var i = 0; i < root.pages.length; i++) {
            var p = root.pages[i]
            var sec = null
            for (var s = 0; s < sections.length; s++)
                if (sections[s].section === p.section) { sec = sections[s]; break }
            if (!sec) {
                sec = { section: p.section, icon: root.sectionIcons[p.section] || "", pages: [] }
                sections.push(sec)
            }
            sec.pages.push(p)
        }
        return sections
    }

    Component { id: wifiComp; WifiPage {} }
    Component { id: bluetoothComp; BluetoothPage {} }
    Component { id: networkComp; NetworkPage {} }
    Component { id: displaysComp; DisplaysPage {} }
    Component { id: inputComp; InputPage {} }
    Component { id: hyprlandComp; HyprlandPage {} }
    Component { id: soundComp; SoundPage {} }
    Component { id: powerComp; PowerPage {} }
    Component { id: datetimeComp; DateTimePage {} }
    Component { id: regionComp; RegionPage {} }
    Component { id: usersComp; UsersPage {} }
    Component { id: defaultsComp; DefaultAppsPage {} }
    Component { id: shortcutsComp; ShortcutsPage {} }
    Component { id: themeComp; ThemePage {} }
    Component { id: fastfetchComp; FastfetchPage {} }
    Component { id: wallpaperComp; WallpaperPage {} }
    Component { id: backgroundsComp; BackgroundsPage {} }
    Component { id: typographyComp; TypographyPage {} }
    Component { id: cursorComp; CursorPage {} }
    Component { id: notificationsComp; NotificationsPage {} }
    Component { id: barComp; BarPage {} }
    Component { id: behaviourComp; BehaviourPage {} }
    Component { id: integrationsComp; IntegrationsPage {} }
    Component { id: advancedComp; AdvancedPage {} }
    Component { id: aboutComp; AboutPage {} }

    function pageMatches(p) {
        if (SettingsSearch.text === "") return true
        var q = SettingsSearch.text.toLowerCase()
        return (p.id + " " + p.label + " " + (p.keywords || "")).toLowerCase().indexOf(q) !== -1
    }

    function sectionMatches(section) {
        for (var i = 0; i < section.pages.length; i++)
            if (pageMatches(section.pages[i])) return true
        return false
    }

    function hasPage(id) {
        for (var i = 0; i < root.pages.length; i++)
            if (root.pages[i].id === id) return true
        return false
    }

    function pageInfo(id) {
        for (var i = 0; i < root.pages.length; i++)
            if (root.pages[i].id === id) return root.pages[i]
        return null
    }

    readonly property var currentPage: pageInfo(root.page)

    // ── Collapsible sidebar sections ───────────────────────────────────────
    property var collapsedSections: ({})

    function isSectionOpen(name) {
        // A search always unfolds: hiding a match behind a fold lies.
        return SettingsSearch.text !== "" || collapsedSections[name] !== true
    }

    function toggleSection(name) {
        var next = {}
        for (var k in collapsedSections) next[k] = collapsedSections[k]
        next[name] = !next[name]
        collapsedSections = next
    }

    // While searching, keep the content on a page that actually matches: a
    // query only filters the sidebar today, which reads as an empty page.
    property bool _searchJump: false

    function focusFirstMatch() {
        if (SettingsSearch.text === "" || !root.currentPage) return
        if (root.pageMatches(root.currentPage)) return
        for (var i = 0; i < root.pages.length; i++) {
            if (root.pageMatches(root.pages[i])) {
                root._searchJump = true
                root.page = root.pages[i].id
                return
            }
        }
    }

    // IPC / keybinds: aim the next settings open at a page ("wifi", "theme", …).
    Connections {
        target: IslandState
        function onSettingsPageChanged() {
            if (IslandState.settingsPage === "") return
            if (root.hasPage(IslandState.settingsPage)) root.page = IslandState.settingsPage
            IslandState.settingsPage = ""
        }
    }

    function anyPageMatches() {
        for (var i = 0; i < navigation.length; i++)
            if (sectionMatches(navigation[i])) return true
        return false
    }

    // Pages load on first visit and stay loaded; a fresh shell only builds
    // the initial page instead of all 25.
    property var visitedPages: ({})

    function _markVisited(id) {
        if (id === "") return
        var next = {}
        for (var k in visitedPages) next[k] = visitedPages[k]
        next[id] = true
        visitedPages = next
    }

    onPageChanged: {
        if (!_searchJump) {
            SettingsSearch.text = ""
            searchInput.text = ""
        }
        _searchJump = false
        flick.contentY = 0
        _markVisited(page)
    }

    // ── Header ─────────────────────────────────────────────────────────────
    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 32

        BackButton {
            id: backIcon
            anchors.verticalCenter: parent.verticalCenter
            onClicked: IslandState.closeToIdle()
        }

        EyeFace {
            id: headerEye
            eyeWidth: 20; eyeHeight: 14; eyeSpacing: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: backIcon.right; anchors.leftMargin: 8
            baseMood: "active"
        }

        Item {
            id: crumb
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: backIcon.right
            anchors.leftMargin: headerEye.visible ? headerEye.width + 16 : 8
            width: Math.max(0, searchBox.x - crumb.x - 12)
            height: 24
            clip: true

            Text {
                id: crumbBrand
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Settings"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
            }

            Text {
                id: crumbSep
                anchors { left: crumbBrand.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: "›"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
            }

            Text {
                id: crumbIcon
                anchors { left: crumbSep.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
                visible: root.currentPage && root.currentPage.icon !== ""
                text: root.currentPage ? root.currentPage.icon : ""
                color: Theme.accent
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.mono
            }

            Text {
                anchors {
                    left: crumbIcon.visible ? crumbIcon.right : crumbSep.right
                    leftMargin: 6
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: root.currentPage ? root.currentPage.label : ""
                color: Theme.text
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
                font.weight: 700
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: searchBox
            width: 260
            height: 28
            radius: Theme.shape.radius.control
            color: Theme.background
            border.color: searchInput.activeFocus ? Theme.accent : Theme.border
            border.width: Theme.shape.border.width
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            Behavior on border.color { ColorAnimation { duration: Theme.motion.hover } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "󰍉"
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.mono
                    color: searchInput.activeFocus ? Theme.accent : Theme.subtext
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 32 - (clearGlyph.visible ? 22 : 0)
                    color: Theme.text
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    clip: true
                    onTextChanged: {
                        SettingsSearch.text = text
                        root.focusFirstMatch()
                    }

                    Text {
                        anchors.fill: parent
                        text: "Search settings..."
                        color: Theme.subtext
                        font.pixelSize: Theme.font.size.small
                        font.family: Theme.font.family
                        visible: searchInput.text.length === 0
                    }

                    Keys.onEscapePressed: searchInput.text = ""
                }

                Text {
                    id: clearGlyph
                    visible: searchInput.text.length > 0
                    text: "󰅖"
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.mono
                    color: clearMouse.containsMouse ? Theme.text : Theme.subtext
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = ""
                            searchInput.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        enabled: IslandState.state === "settings"
        onActivated: {
            searchInput.forceActiveFocus()
            searchInput.selectAll()
        }
    }

    Rectangle {
        id: divider
        anchors { left: parent.left; right: parent.right; top: header.bottom; topMargin: 10 }
        height: 1
        color: Theme.border
        opacity: 0.5
    }

    // ── Body ───────────────────────────────────────────────────────────────
    Row {
        id: body
        anchors { left: parent.left; right: parent.right; top: divider.bottom; topMargin: 10; bottom: parent.bottom }
        spacing: 12

        Item {
            id: sidebarHost
            width: 196
            height: parent.height

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
                        visible: !root.anyPageMatches()

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
                        model: root.navigation

                        delegate: Column {
                            id: navSection
                            required property var modelData
                            width: sidebarColumn.width
                            spacing: 1
                            visible: root.sectionMatches(navSection.modelData)

                            readonly property bool activeGroup: {
                                for (var i = 0; i < navSection.modelData.pages.length; i++)
                                    if (navSection.modelData.pages[i].id === root.page) return true
                                return false
                            }

                            readonly property bool folded: !root.isSectionOpen(navSection.modelData.section)

                            // ── Section header (click to fold) ──────────────
                            Item {
                                id: navHead
                                width: parent.width
                                height: 30

                                Row {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 7

                                    Text {
                                        text: navSection.modelData.icon
                                        visible: text !== ""
                                        color: navSection.activeGroup ? Theme.accent
                                            : (headMouse.containsMouse ? Theme.text : Theme.subtext)
                                        font.pixelSize: Theme.font.size.small
                                        font.family: Theme.font.mono
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                                    }

                                    Text {
                                        text: navSection.modelData.section.toUpperCase()
                                        color: (navSection.activeGroup || headMouse.containsMouse) ? Theme.text : Theme.subtext
                                        font.pixelSize: Theme.font.size.caption
                                        font.family: Theme.font.family
                                        font.weight: 700
                                        font.letterSpacing: 0.7
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: Theme.motion.hover } }
                                    }
                                }

                                Text {
                                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
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
                                    visible: root.pageMatches(navItem.modelData) && !navSection.folded
                                    width: sidebarColumn.width
                                    height: visible ? 34 : 0
                                    radius: Theme.shape.radius.row
                                    color: root.page === navItem.modelData.id
                                        ? Theme.accent
                                        : (navMouse.containsMouse ? Theme.surfaceHover : "transparent")
                                    Behavior on color { ColorAnimation { duration: Theme.motion.hover } }

                                    Row {
                                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                        spacing: 8

                                        Text {
                                            width: 18
                                            horizontalAlignment: Text.AlignHCenter
                                            text: navItem.modelData.icon
                                            color: root.page === navItem.modelData.id ? Theme.background : Theme.text
                                            font.pixelSize: Theme.font.size.large
                                            font.family: Theme.font.mono
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            width: navItem.width - 12 - 18 - 8 - 10
                                            text: navItem.modelData.label
                                            color: root.page === navItem.modelData.id ? Theme.background : Theme.text
                                            font.pixelSize: Theme.font.size.normal
                                            font.family: Theme.font.family
                                            font.weight: root.page === navItem.modelData.id ? 700 : 500
                                            elide: Text.ElideRight
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: navMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.page = navItem.modelData.id
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Sidebar scroll affordance
            Rectangle {
                x: sidebarHost.width - 5
                width: 3
                radius: 1.5
                color: Theme.subtext
                opacity: 0.4
                visible: sidebarFlick.contentHeight > sidebarFlick.height
                height: Math.max(24, sidebarFlick.height * sidebarFlick.height / sidebarFlick.contentHeight)
                y: sidebarFlick.contentHeight > sidebarFlick.height
                    ? (sidebarFlick.contentY / (sidebarFlick.contentHeight - sidebarFlick.height)) * (sidebarFlick.height - height)
                    : 0
            }
        }

        Item {
            id: contentHost
            width: body.width - sidebarHost.width - body.spacing
            height: parent.height

            Flickable {
                id: flick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: pagesColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: pagesColumn
                    width: flick.width
                    spacing: 4

                    Repeater {
                        model: root.pages

                        delegate: Loader {
                            id: pageLoader
                            required property var modelData
                            width: parent.width
                            visible: root.page === modelData.id
                            active: root.page === modelData.id || root.visitedPages[modelData.id] === true
                            sourceComponent: modelData.component

                            onLoaded: item.active = Qt.binding(function() {
                                return root.page === pageLoader.modelData.id
                            })
                        }
                    }
                }
            }

            Rectangle {
                width: 3
                radius: 1.5
                color: Theme.subtext
                opacity: 0.5
                visible: flick.contentHeight > flick.height
                x: flick.width - 5
                height: Math.max(24, flick.height * flick.height / flick.contentHeight)
                y: flick.contentHeight > flick.height
                    ? (flick.contentY / (flick.contentHeight - flick.height)) * (flick.height - height)
                    : 0
            }
        }
    }
}
