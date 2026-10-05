import QtQuick
import "../../components"

// Visual resolution picker for one monitor: a card per resolution with an
// aspect-true preview and that mode's refresh-rate chips. The catalogue only
// rebuilds when the monitor's mode list really changes — a monitor readback
// after a write replaces the object with identical data, which would
// otherwise rebuild the gallery and every chip. Picking a rate is reported to
// the page, which owns the compositor write.
Grid {
    id: gallery

    property var monitor: null
    signal modeChosen(int w, int h, real hz)

    width: parent.width
    columns: 3
    spacing: 8

    readonly property string modeSignature: {
        var m = gallery.monitor;
        if (!m)
            return "";
        return m.name + "|" + (m.availableModes || []).join(",");
    }

    property var modeGroups: []

    function parseMode(s) {
        var m = /^(\d+)x(\d+)@([\d.]+)/.exec(String(s));
        return m ? {
            w: parseInt(m[1]),
            h: parseInt(m[2]),
            hz: parseFloat(m[3])
        } : null;
    }

    function rebuildModeGroups() {
        var sm = gallery.monitor;
        var modes = sm ? (sm.availableModes || []) : [];
        var groups = [], byKey = {};
        for (var i = 0; i < modes.length; i++) {
            var p = parseMode(modes[i]);
            if (!p)
                continue;
            var key = p.w + "x" + p.h;
            if (!byKey[key]) {
                byKey[key] = {
                    w: p.w,
                    h: p.h,
                    area: p.w * p.h,
                    rates: []
                };
                groups.push(byKey[key]);
            }
            byKey[key].rates.push(p.hz);
        }
        groups.sort(function (a, b) {
            return b.area - a.area;
        });
        for (i = 0; i < groups.length; i++) {
            var seen = {};
            groups[i].rates = groups[i].rates.filter(function (hz) {
                var k = hz.toFixed(1);
                if (seen[k])
                    return false;
                seen[k] = true;
                return true;
            }).sort(function (a, b) {
                return b - a;
            });
        }
        gallery.modeGroups = groups;
    }

    onModeSignatureChanged: rebuildModeGroups()
    Component.onCompleted: rebuildModeGroups()

    function isCurrentMode(g, hz) {
        var m = gallery.monitor;
        if (!m)
            return false;
        return m.width === g.w && m.height === g.h && Math.abs(Number(m.refreshRate) - hz) < 0.6;
    }

    function screenFit(w, h, maxW, maxH) {
        var r = w / Math.max(1, h);
        return r > maxW / maxH ? {
            w: maxW,
            h: Math.round(maxW / r)
        } : {
            w: Math.round(maxH * r),
            h: maxH
        };
    }

    Repeater {
        model: gallery.modeGroups

        delegate: Rectangle {
            id: modeCard
            required property var modelData
            readonly property bool hovered: modeHover.hovered
            readonly property var fit: gallery.screenFit(modelData.w, modelData.h, 84, 48)
            readonly property bool activeGroup: gallery.monitor && gallery.monitor.width === modelData.w && gallery.monitor.height === modelData.h

            width: (gallery.width - gallery.spacing * 2) / 3
            height: modeCol.implicitHeight + 20
            radius: Theme.shape.radius.row
            color: activeGroup ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10) : (hovered ? Theme.surfaceHover : Theme.surface)
            border.width: activeGroup ? Theme.shape.border.emphasis : Theme.shape.border.width
            border.color: activeGroup ? Theme.accent : (hovered ? Theme.subtext : Theme.border)
            scale: hovered ? 1.02 : 1
            Behavior on scale {
                NumberAnimation {
                    duration: Theme.motion.fast
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Theme.motion.hover
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.motion.hover
                }
            }
            Behavior on border.width {
                NumberAnimation {
                    duration: Theme.motion.hover
                }
            }

            Column {
                id: modeCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                spacing: 6

                // aspect-true mini screen
                Item {
                    width: parent.width
                    height: 48

                    Rectangle {
                        anchors.centerIn: parent
                        width: modeCard.fit.w
                        height: modeCard.fit.h
                        radius: 3
                        color: modeCard.activeGroup ? Theme.highlight : Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.55)
                        border.width: modeCard.activeGroup ? 2 : 1
                        border.color: modeCard.activeGroup ? Theme.accent : Theme.border
                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.motion.hover
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: Theme.motion.hover
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰍹"
                            color: modeCard.activeGroup ? Theme.accent : Theme.subtext
                            font.pixelSize: Theme.font.size.small
                            font.family: Theme.font.mono
                        }
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: modeCard.modelData.w + "×" + modeCard.modelData.h
                    color: Theme.text
                    font.pixelSize: Theme.font.size.small
                    font.family: Theme.font.family
                    font.weight: modeCard.activeGroup ? 700 : 500
                }

                Flow {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: modeCard.modelData.rates

                        delegate: Rectangle {
                            id: rateChip
                            required property real modelData
                            readonly property bool on: gallery.isCurrentMode(modeCard.modelData, rateChip.modelData)
                            width: rateText.implicitWidth + 12
                            height: 20
                            radius: Theme.shape.radius.hairline
                            color: on ? Theme.accent : (rateHover.hovered ? Theme.highlight : Theme.background)
                            border.width: on ? 0 : Theme.shape.border.width
                            border.color: Theme.border
                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.motion.fast
                                }
                            }

                            Text {
                                id: rateText
                                anchors.centerIn: parent
                                text: Number(rateChip.modelData).toFixed(Number(rateChip.modelData) % 1 === 0 ? 0 : 1) + " Hz"
                                color: on ? Theme.background : Theme.text
                                font.pixelSize: Theme.font.size.caption
                                font.family: Theme.font.mono
                                font.weight: on ? 700 : 400
                            }

                            HoverHandler {
                                id: rateHover
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: gallery.modeChosen(modeCard.modelData.w, modeCard.modelData.h, rateChip.modelData)
                            }
                        }
                    }
                }
            }

            HoverHandler {
                id: modeHover
                cursorShape: Qt.PointingHandCursor
            }

            // selected check pops in
            Rectangle {
                visible: opacity > 0
                opacity: modeCard.activeGroup ? 1 : 0
                anchors {
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                width: 16
                height: 16
                radius: 8
                color: Theme.accent
                scale: modeCard.activeGroup ? 1 : 0.4
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.motion.fast
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.motion.fast
                        easing.type: Easing.OutBack
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: Theme.background
                    font.pixelSize: Theme.font.size.caption
                    font.family: Theme.font.family
                    font.weight: 800
                }
            }
        }
    }
}
