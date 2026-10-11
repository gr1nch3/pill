// Whole-system settings workspace: fixed size, sectioned scrollable sidebar,
// page content scrolls independently. Option A navigation — one sidebar,
// complex pages drill down inside the content area.
import QtQuick

import "../services"
import "../components"
import "../eyes"
import "pages"
import "PageMatch.js" as PageMatch

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
        function onReadyChanged() {
            if (root.page === "")
                root.page = root.initialPage;
        }
    }

    Component.onCompleted: if (Integrations.ready && root.page === "")
        root.page = root.initialPage

    // One registry row per page: nav metadata + the component to load.
    // Sidebar sections and search derive from it; adding a page is one row
    // plus one Component line.
    readonly property var pages: [
        {
            id: "profile",
            section: "Account",
            label: "Profile",
            icon: "󰀄",
            keywords: "user avatar name password account uid",
            desc: "Your account, avatar and password.",
            component: profileComp
        },
        {
            id: "wifi",
            section: "Connections",
            label: "Wi-Fi",
            icon: "󰖩",
            keywords: "wlan wireless network",
            desc: "Pick a network and connect; saved networks stay remembered.",
            component: wifiComp
        },
        {
            id: "bluetooth",
            section: "Connections",
            label: "Bluetooth",
            icon: "󰂯",
            keywords: "bt devices pair",
            desc: "Power, discover and pair nearby devices.",
            component: bluetoothComp
        },
        {
            id: "network",
            section: "Connections",
            label: "Ethernet & VPN",
            icon: "󰈀",
            keywords: "wired vpn profile nmcli",
            desc: "Wired and VPN profiles managed by NetworkManager.",
            component: networkComp
        },
        {
            id: "displays",
            section: "Desktop",
            label: "Displays",
            icon: "󰍹",
            keywords: "monitor resolution scale refresh",
            desc: "Arrange your screens and pick each one's mode.",
            component: displaysComp
        },
        {
            id: "input",
            section: "Desktop",
            label: "Input",
            icon: "󰌌",
            keywords: "keyboard mouse touchpad layout",
            desc: "Keyboard and pointer behaviour from the compositor.",
            component: inputComp
        },
        {
            id: "hyprland",
            section: "Desktop",
            label: "Hyprland",
            icon: "󰣖",
            keywords: "gaps decoration blur animations",
            desc: "Gaps, borders, blur and animations for Hyprland.",
            component: hyprlandComp
        },
        {
            id: "shortcuts",
            section: "Desktop",
            label: "Keyboard Shortcuts",
            icon: "󰘮",
            keywords: "binds keybinds hyprland",
            desc: "Every keybind the compositor reports, read-only.",
            component: shortcutsComp
        },
        {
            id: "sound",
            section: "System",
            label: "Sound",
            icon: "󰕾",
            keywords: "audio volume output input mic",
            desc: "Output and input devices, volumes and mute.",
            component: soundComp
        },
        {
            id: "power",
            section: "System",
            label: "Power",
            icon: "󰐥",
            keywords: "battery profile suspend idle",
            desc: "Battery, power profile and idle behaviour.",
            component: powerComp
        },
        {
            id: "datetime",
            section: "System",
            label: "Date & Time",
            icon: "󰅐",
            keywords: "clock timezone ntp",
            desc: "Timezone, NTP and the shell clock format.",
            component: datetimeComp
        },
        {
            id: "region",
            section: "System",
            label: "Region & Language",
            icon: "󰗊",
            keywords: "locale language keymap",
            desc: "Locale, language and keymap information.",
            component: regionComp
        },
        {
            id: "defaults",
            section: "System",
            label: "Default Apps",
            icon: "󰈙",
            keywords: "browser mail mime associations",
            desc: "Which application opens what.",
            component: defaultsComp
        },
        {
            id: "theme",
            section: "Appearance",
            label: "Theme",
            icon: "󰏘",
            keywords: "colors palette user themes",
            desc: "Palette, user themes and the shell's shape language.",
            component: themeComp
        },
        {
            id: "wallpaper",
            section: "Appearance",
            label: "Wallpaper",
            icon: "󰋩",
            keywords: "background image",
            desc: "Library folder and the current background.",
            component: wallpaperComp
        },
        {
            id: "backgrounds",
            section: "Appearance",
            label: "Backgrounds",
            icon: "󰏘",
            keywords: "pattern dots grid lock sign-in greeter sddm",
            desc: "Panel patterns and the lock/sign-in look.",
            component: backgroundsComp
        },
        {
            id: "typography",
            section: "Appearance",
            label: "Typography",
            icon: "󰎆",
            keywords: "font scale text",
            desc: "UI and icon fonts, and the type scale.",
            component: typographyComp
        },
        {
            id: "cursor",
            section: "Appearance",
            label: "Cursor & Icons",
            icon: "󰆿",
            keywords: "gtk icon theme pointer",
            desc: "Pointer and icon themes for GTK apps.",
            component: cursorComp
        },
        {
            id: "fastfetch",
            section: "Appearance",
            label: "Fastfetch",
            icon: "󰄨",
            keywords: "fetch system info ascii logo theme terminal",
            desc: "Theme the terminal fetch from the shell palette.",
            component: fastfetchComp
        },
        {
            id: "bar",
            section: "Shell",
            label: "Bar & Eyes",
            icon: "󰈈",
            keywords: "pill position pin eyes",
            desc: "Bar position, pin behaviour and the eyes.",
            component: barComp
        },
        {
            id: "behaviour",
            section: "Shell",
            label: "Behaviour",
            icon: "󰒓",
            keywords: "auto hide osd delay",
            desc: "Auto-hide and on-screen display timing.",
            component: behaviourComp
        },
        {
            id: "notifications",
            section: "Shell",
            label: "Notifications",
            icon: "󰂚",
            keywords: "popups dnd sounds timeout",
            desc: "Popups, history and event sounds.",
            component: notificationsComp
        },
        {
            id: "integrations",
            section: "Shell",
            label: "Integrations",
            icon: "󱁤",
            keywords: "tools gtk qt retint wallust",
            desc: "System theme sync, retemplating and tool checks.",
            component: integrationsComp
        },
        {
            id: "advanced",
            section: "Shell",
            label: "Advanced",
            icon: "󰉋",
            keywords: "folders paths",
            desc: "Config and asset folders.",
            component: advancedComp
        },
        {
            id: "about",
            section: "About",
            label: "About",
            icon: "󰋜",
            keywords: "system info version session",
            desc: "System info and session actions.",
            component: aboutComp
        },
    ]

    readonly property var sectionIcons: ({
            "Account": "󰀄",
            "Connections": "󰖩",
            "Desktop": "󰍹",
            "System": "󰌢",
            "Appearance": "󰏘",
            "Shell": "󰒓",
            "About": "󰋜"
        })

    readonly property var navigation: {
        var sections = [];
        for (var i = 0; i < root.pages.length; i++) {
            var p = root.pages[i];
            var sec = null;
            for (var s = 0; s < sections.length; s++)
                if (sections[s].section === p.section) {
                    sec = sections[s];
                    break;
                }
            if (!sec) {
                sec = {
                    section: p.section,
                    icon: root.sectionIcons[p.section] || "",
                    pages: []
                };
                sections.push(sec);
            }
            sec.pages.push(p);
        }
        return sections;
    }

    Component {
        id: wifiComp
        WifiPage {}
    }
    Component {
        id: bluetoothComp
        BluetoothPage {}
    }
    Component {
        id: networkComp
        NetworkPage {}
    }
    Component {
        id: displaysComp
        DisplaysPage {}
    }
    Component {
        id: inputComp
        InputPage {}
    }
    Component {
        id: hyprlandComp
        HyprlandPage {}
    }
    Component {
        id: soundComp
        SoundPage {}
    }
    Component {
        id: powerComp
        PowerPage {}
    }
    Component {
        id: datetimeComp
        DateTimePage {}
    }
    Component {
        id: regionComp
        RegionPage {}
    }
    Component {
        id: defaultsComp
        DefaultAppsPage {}
    }
    Component {
        id: shortcutsComp
        ShortcutsPage {}
    }
    Component {
        id: themeComp
        ThemePage {}
    }
    Component {
        id: fastfetchComp
        FastfetchPage {}
    }
    Component {
        id: wallpaperComp
        WallpaperPage {}
    }
    Component {
        id: backgroundsComp
        BackgroundsPage {}
    }
    Component {
        id: typographyComp
        TypographyPage {}
    }
    Component {
        id: cursorComp
        CursorPage {}
    }
    Component {
        id: notificationsComp
        NotificationsPage {}
    }
    Component {
        id: barComp
        BarPage {}
    }
    Component {
        id: behaviourComp
        BehaviourPage {}
    }
    Component {
        id: integrationsComp
        IntegrationsPage {}
    }
    Component {
        id: advancedComp
        AdvancedPage {}
    }
    Component {
        id: profileComp
        ProfilePage {}
    }
    Component {
        id: aboutComp
        AboutPage {}
    }

    function pageMatches(p) {
        return PageMatch.matches(p, SettingsSearch.text);
    }

    function hasPage(id) {
        for (var i = 0; i < root.pages.length; i++)
            if (root.pages[i].id === id)
                return true;
        return false;
    }

    function pageInfo(id) {
        for (var i = 0; i < root.pages.length; i++)
            if (root.pages[i].id === id)
                return root.pages[i];
        return null;
    }

    readonly property var currentPage: pageInfo(root.page)

    // While searching, keep the content on a page that actually matches: a
    // query only filters the sidebar today, which reads as an empty page.
    property bool _searchJump: false

    function focusFirstMatch() {
        if (SettingsSearch.text === "" || !root.currentPage)
            return;
        if (root.pageMatches(root.currentPage))
            return;
        for (var i = 0; i < root.pages.length; i++) {
            if (root.pageMatches(root.pages[i])) {
                root._searchJump = true;
                root.page = root.pages[i].id;
                return;
            }
        }
    }

    // IPC / keybinds: aim the next settings open at a page ("wifi", "theme", …).
    Connections {
        target: IslandState
        function onSettingsPageChanged() {
            if (IslandState.settingsPage === "")
                return;
            // the old Users page is now Profile
            var target = IslandState.settingsPage === "users" ? "profile" : IslandState.settingsPage;
            if (root.hasPage(target))
                root.page = target;
            IslandState.settingsPage = "";
        }
    }

    // Pages load on first visit and stay loaded; a fresh shell only builds
    // the initial page instead of all 25.
    property var visitedPages: ({})

    function _markVisited(id) {
        if (id === "")
            return;
        var next = {};
        for (var k in visitedPages)
            next[k] = visitedPages[k];
        next[id] = true;
        visitedPages = next;
    }

    onPageChanged: {
        if (!_searchJump) {
            SettingsSearch.text = "";
            searchInput.text = "";
        }
        _searchJump = false;
        flick.contentY = 0;
        _markVisited(page);
    }

    // ── Header ─────────────────────────────────────────────────────────────
    Item {
        id: header
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: 32

        BackButton {
            id: backIcon
            anchors.verticalCenter: parent.verticalCenter
            onClicked: IslandState.closeToIdle()
        }

        EyeFace {
            id: headerEye
            eyeWidth: 20
            eyeHeight: 14
            eyeSpacing: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: backIcon.right
            anchors.leftMargin: 8
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
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                text: "Settings"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
            }

            Text {
                id: crumbSep
                anchors {
                    left: crumbBrand.right
                    leftMargin: 6
                    verticalCenter: parent.verticalCenter
                }
                text: "›"
                color: Theme.subtext
                font.pixelSize: Theme.font.size.large
                font.family: Theme.font.family
            }

            Text {
                id: crumbIcon
                anchors {
                    left: crumbSep.right
                    leftMargin: 6
                    verticalCenter: parent.verticalCenter
                }
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
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.motion.hover
                }
            }

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
                        // Clearing is instant; typing fans out to every row of
                        // every visited page, so it lands on a typing pause.
                        if (text === "") {
                            searchDebounce.stop();
                            SettingsSearch.text = "";
                            root.focusFirstMatch();
                        } else {
                            searchDebounce.restart();
                        }
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
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
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
            searchInput.forceActiveFocus();
            searchInput.selectAll();
        }
    }

    Timer {
        id: searchDebounce
        interval: 120
        onTriggered: {
            SettingsSearch.text = searchInput.text;
            root.focusFirstMatch();
        }
    }

    Rectangle {
        id: divider
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            topMargin: 10
        }
        height: 1
        color: Theme.border
        opacity: 0.5
    }

    // ── Body ───────────────────────────────────────────────────────────────
    Row {
        id: body
        anchors {
            left: parent.left
            right: parent.right
            top: divider.bottom
            topMargin: 10
            bottom: parent.bottom
        }
        spacing: 12

        SettingsSidebar {
            id: sidebar
            sections: root.navigation
            currentPage: root.page
            width: 196
            height: parent.height
            onPagePicked: function (id) {
                root.page = id;
            }
        }

        Item {
            id: contentHost
            width: body.width - sidebar.width - body.spacing
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

                            onLoaded: {
                                // qmllint can't type dynamically loaded pages
                                // (Loader.item is a plain QObject); every
                                // settings page sets these four properties.
                                // qmllint disable missing-property
                                item.active = Qt.binding(function () {
                                    return root.page === pageLoader.modelData.id;
                                });
                                // page header metadata comes from the registry
                                item.pageTitle = pageLoader.modelData.label;
                                item.pageIcon = pageLoader.modelData.icon;
                                item.pageDesc = pageLoader.modelData.desc || "";
                                // qmllint enable missing-property
                            }
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
                y: flick.contentHeight > flick.height ? (flick.contentY / (flick.contentHeight - flick.height)) * (flick.height - height) : 0
            }
        }
    }
}
