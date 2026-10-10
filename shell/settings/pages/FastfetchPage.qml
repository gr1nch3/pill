import QtQuick
import "../../components"

import "../../services"
import "../controls"

SettingsPage {
    id: root

    actions: [
        {
            label: "Apply Now",
            icon: "󰒓",
            accent: true,
            onTrigger: function () {
                Fastfetch.sync(true);
            }
        }
    ]

    property string customDraft: ""

    // ── Module picker state ────────────────────────────────────────────────
    property var moduleDraft: []
    property string moduleFilter: ""

    readonly property var keyTypeOptions: [
        {
            value: "string",
            label: "Labels"
        },
        {
            value: "both",
            label: "Labels + icons"
        },
        {
            value: "icon",
            label: "Icons only"
        },
        {
            value: "none",
            label: "Value only"
        }
    ]

    function parseModules(raw) {
        var parts = String(raw || "").split(/[,\n]/);
        var out = [];
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim();
            if (p !== "" && out.indexOf(p) === -1)
                out.push(p);
        }
        return out;
    }

    function moduleSubtitle() {
        var names = root.parseModules(Config.fastfetchModules);
        if (names.length === 0)
            return Fastfetch.defaultModules.length + " modules — the default set";
        return names.length + " modules — " + names.slice(0, 3).join(", ") + (names.length > 3 ? ", …" : "");
    }

    function moduleTitle(name) {
        var meta = Fastfetch.moduleMeta(name);
        if (meta && meta.verbose)
            return meta.verbose;
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function openModulePicker() {
        var names = root.parseModules(Config.fastfetchModules);
        root.moduleDraft = names.length > 0 ? names : Fastfetch.defaultModules.slice();
        root.moduleFilter = "";
        moduleDialog.open();
    }

    function toggleModule(name) {
        var d = root.moduleDraft.slice();
        var i = d.indexOf(name);
        if (i === -1) {
            d.push(name);
        } else {
            // Never empty: an empty string means "use the default set".
            if (d.length <= 1)
                return;
            d.splice(i, 1);
        }
        root.moduleDraft = d;
    }

    function moveModule(index, step) {
        var d = root.moduleDraft.slice();
        var j = index + step;
        if (index < 0 || j < 0 || j >= d.length)
            return;
        var swap = d[index];
        d[index] = d[j];
        d[j] = swap;
        root.moduleDraft = d;
    }

    function saveModules() {
        Config.set("fastfetchModules", root.moduleDraft.join(", "));
        Fastfetch.sync(true);
        moduleDialog.close();
    }

    // Enabled draft in order, then everything else in catalog order, filtered
    // by the dialog's search text. index = draft position for the arrows.
    readonly property var moduleRows: {
        var rows = [];
        var draft = root.moduleDraft;
        for (var i = 0; i < draft.length; i++)
            rows.push({
                name: draft[i],
                enabled: true,
                index: i,
                meta: Fastfetch.moduleMeta(draft[i])
            });
        var cat = Fastfetch.moduleCatalog;
        for (var c = 0; c < cat.length; c++) {
            if (draft.indexOf(cat[c].name) === -1)
                rows.push({
                    name: cat[c].name,
                    enabled: false,
                    index: -1,
                    meta: cat[c]
                });
        }
        var q = root.moduleFilter.trim().toLowerCase();
        if (q === "")
            return rows;
        var out = [];
        for (var r = 0; r < rows.length; r++) {
            var m = rows[r].meta;
            if (rows[r].name.toLowerCase().indexOf(q) !== -1 || (m && m.desc.toLowerCase().indexOf(q) !== -1))
                out.push(rows[r]);
        }
        return out;
    }

    readonly property var logoOptions: [
        {
            value: "auto",
            label: "Auto (distro logo)"
        },
        {
            value: "pill",
            label: "Pill (three bubbles)"
        },
        {
            value: "none",
            label: "None"
        },
        {
            value: "arch",
            label: "Arch"
        },
        {
            value: "cachyos",
            label: "CachyOS"
        },
        {
            value: "endeavouros",
            label: "EndeavourOS"
        },
        {
            value: "fedora",
            label: "Fedora"
        },
        {
            value: "ubuntu",
            label: "Ubuntu"
        },
        {
            value: "debian",
            label: "Debian"
        },
        {
            value: "opensuse",
            label: "openSUSE"
        },
        {
            value: "nixos",
            label: "NixOS"
        },
        {
            value: "void",
            label: "Void"
        },
        {
            value: "gentoo",
            label: "Gentoo"
        },
        {
            value: "alpine",
            label: "Alpine"
        },
        {
            value: "__custom",
            label: "Custom…"
        }
    ]

    function pickLogo(value) {
        if (value === "__custom") {
            root.customDraft = Config.fastfetchLogo;
            customLogoDialog.open();
            return;
        }
        Config.set("fastfetchLogo", value);
        Fastfetch.sync(true);
    }

    function saveCustomLogo() {
        Config.set("fastfetchLogo", root.customDraft.trim());
        Fastfetch.sync(true);
        customLogoDialog.close();
    }

    SettingRow {
        icon: "󰄨"
        title: "Theme fastfetch"
        subtitle: "Write ~/.config/fastfetch/config.jsonc from the Pill palette on every theme change"
        SettingToggle {
            value: Config.fastfetchEnabled
            onValueEdited: function (v) {
                Config.set("fastfetchEnabled", v);
                if (v)
                    Fastfetch.sync(true);
            }
        }
    }

    SettingRow {
        icon: "󰋩"
        title: "Logo"
        subtitle: "The mark printed beside the fetch; Custom covers any builtin, small:<name> or file path"
        SettingSelect {
            width: 230
            options: root.logoOptions
            currentValue: Config.fastfetchLogo !== "" ? Config.fastfetchLogo : "auto"
            placeholder: "auto"
            onValueSelected: function (value) {
                root.pickLogo(value);
            }
        }
    }

    SettingRow {
        icon: "󰌒"
        title: "Key labels"
        subtitle: "Print module names beside their values, as icons, or not at all"
        keywords: "key labels icons hide output style"
        SettingSelect {
            width: 200
            options: root.keyTypeOptions
            currentValue: Config.fastfetchKeyType
            placeholder: "Labels"
            onValueSelected: function (value) {
                Config.set("fastfetchKeyType", value);
                Fastfetch.sync(true);
            }
        }
    }

    SettingRow {
        icon: "󰌒"
        title: "Long key names"
        subtitle: "Print “Window Manager” instead of “WM”; key column width auto-fits"
        keywords: "verbose long keys window manager spacing align width"
        visibleWhen: Config.fastfetchKeyType !== "none"
        SettingToggle {
            value: Config.fastfetchVerboseKeys
            onValueEdited: function (v) {
                Config.set("fastfetchVerboseKeys", v);
                Fastfetch.sync(true);
            }
        }
    }

    SettingRow {
        icon: "󰒺"
        title: "Modules"
        subtitle: root.moduleSubtitle()
        keywords: "modules lines picker reorder layout choose"
        SettingAction {
            label: "Edit…"
            onClicked: root.openModulePicker()
        }
    }

    SettingRow {
        icon: "󰒓"
        title: "Status"
        subtitle: !Config.fastfetchEnabled ? "Disabled" : !Integrations.has("fastfetch") ? "fastfetch is not installed" : Fastfetch.syncing ? "Writing..." : Fastfetch.everSynced ? (Fastfetch.lastOk ? "config.jsonc matches the current palette" : "Failed: " + Fastfetch.lastError) : "Waiting for the first write"
        subtitleTone: !Config.fastfetchEnabled ? "muted" : !Integrations.has("fastfetch") ? "warning" : Fastfetch.syncing || !Fastfetch.everSynced ? "muted" : Fastfetch.lastOk ? "success" : "danger"
        SettingAction {
            label: "Apply Now"
            onClicked: Fastfetch.sync(true)
        }
    }

    SettingNote {
        text: "A pre-existing config is backed up once to ~/.local/state/pill/backup/fastfetch-config.jsonc. Colours come from the palette; logo, key labels and modules are yours to pick above. Run `fastfetch` in any terminal to see it."
    }

    SettingDialog {
        id: customLogoDialog
        title: "Custom logo"
        description: "A fastfetch builtin name, small:<name>, or a path to an image/text file."

        SettingEdit {
            id: customField
            width: parent.width
            textAlign: Text.AlignLeft
            live: true
            value: root.customDraft
            placeholder: "small:arch or /home/…/logo.png"
            onTextEdited: function (text) {
                root.customDraft = text;
            }
            onAccepted: root.saveCustomLogo()
        }

        Item {
            width: parent.width
            height: 30

            Row {
                anchors.right: parent.right
                spacing: 8

                SettingAction {
                    label: "Cancel"
                    onClicked: customLogoDialog.close()
                }
                SettingAction {
                    label: "Save"
                    accent: true
                    onClicked: root.saveCustomLogo()
                }
            }
        }

        onOpened: customField.focusInput()
    }

    SettingDialog {
        id: moduleDialog
        width: 460
        title: "Modules"
        description: "Pick the lines fastfetch prints and their order. The key column auto-fits the longest name."

        SettingEdit {
            width: parent.width
            live: true
            value: root.moduleFilter
            placeholder: "Filter modules…"
            onTextEdited: function (text) {
                root.moduleFilter = text;
            }
        }

        Rectangle {
            width: parent.width
            height: 300
            radius: Theme.shape.radius.card
            color: Theme.background

            Flickable {
                id: moduleFlick
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                contentWidth: width
                contentHeight: moduleColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: moduleColumn
                    width: moduleFlick.width
                    spacing: 2

                    Repeater {
                        model: root.moduleRows

                        delegate: Rectangle {
                            id: moduleRow
                            required property var modelData
                            width: moduleColumn.width
                            height: 42
                            radius: Theme.shape.radius.row
                            color: rowHover.hovered ? Theme.surfaceHover : "transparent"

                            HoverHandler {
                                id: rowHover
                            }

                            Row {
                                visible: moduleRow.modelData.enabled
                                anchors {
                                    left: parent.left
                                    leftMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 2

                                Text {
                                    text: "󰅃"
                                    color: upMouse.enabled && upMouse.containsMouse ? Theme.text : Theme.subtext
                                    opacity: upMouse.enabled ? 1 : 0.3
                                    font.pixelSize: Theme.font.size.small
                                    font.family: Theme.font.mono
                                    anchors.verticalCenter: parent.verticalCenter

                                    MouseArea {
                                        id: upMouse
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        enabled: moduleRow.modelData.index > 0
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.moveModule(moduleRow.modelData.index, -1)
                                    }
                                }

                                Text {
                                    text: "󰅀"
                                    color: downMouse.enabled && downMouse.containsMouse ? Theme.text : Theme.subtext
                                    opacity: downMouse.enabled ? 1 : 0.3
                                    font.pixelSize: Theme.font.size.small
                                    font.family: Theme.font.mono
                                    anchors.verticalCenter: parent.verticalCenter

                                    MouseArea {
                                        id: downMouse
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        enabled: moduleRow.modelData.index >= 0 && moduleRow.modelData.index < root.moduleDraft.length - 1
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.moveModule(moduleRow.modelData.index, 1)
                                    }
                                }
                            }

                            Column {
                                anchors {
                                    left: parent.left
                                    leftMargin: moduleRow.modelData.enabled ? 46 : 12
                                    right: moduleToggle.left
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 0

                                Text {
                                    width: parent.width
                                    text: root.moduleTitle(moduleRow.modelData.name)
                                    color: Theme.text
                                    font.pixelSize: Theme.font.size.small
                                    font.family: Theme.font.family
                                    font.weight: 600
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: moduleRow.modelData.meta ? moduleRow.modelData.meta.desc : ""
                                    color: Theme.subtext
                                    font.pixelSize: Theme.font.size.caption
                                    font.family: Theme.font.family
                                    elide: Text.ElideRight
                                }
                            }

                            SettingToggle {
                                id: moduleToggle
                                anchors {
                                    right: parent.right
                                    rightMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                value: moduleRow.modelData.enabled
                                onValueEdited: root.toggleModule(moduleRow.modelData.name)
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 30

            SettingAction {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                label: "Defaults"
                onClicked: root.moduleDraft = Fastfetch.defaultModules.slice()
            }

            Row {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8

                SettingAction {
                    label: "Cancel"
                    onClicked: moduleDialog.close()
                }
                SettingAction {
                    label: "Save"
                    accent: true
                    onClicked: root.saveModules()
                }
            }
        }
    }
}
