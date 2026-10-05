pragma Singleton
// Owns the notification server and the pill's copy of the list. Callers use
// dismiss(id)/clear(); no field marshalling, no list indexes.
//
// The server updates a Notification object IN PLACE when an app replaces one
// (replaces_id): onNotification only fires for brand-new notifications, so a
// one-shot snapshot leaves the pill stuck on the first version. The copied
// entry is therefore kept live from the object's property-changed signals and
// dropped when the notification closes or expires.
import QtQuick
import Quickshell.Services.Notifications

import "../utils"

Item {
    id: root

    property var notificationList: []
    property bool doNotDisturb: false

    // Emitted for a new notification once the server is past boot replay;
    // shell.qml decides whether to show the pill. `emptied` fires when the
    // last entry goes away (closed, expired or dismissed).
    signal received
    signal emptied

    // Maps entry ids to the live server objects so dismiss/clear actually
    // close them (NotificationClosed), not just hide the pill copy.
    property var _serverNotifs: ({})

    function _entry(notif) {
        return {
            summary: notif.summary || "",
            body: notif.body || "",
            appName: notif.appName || "",
            appIcon: notif.appIcon || "",
            image: notif.image || "",
            urgency: notif.urgency || 1,
            id: notif.id
        };
    }

    // Refresh the listed entry from the live object. Replacement updates
    // (media players, chat apps) change summary/body without a new arrival.
    function _sync(notif) {
        for (var i = 0; i < root.notificationList.length; i++) {
            if (root.notificationList[i].id !== notif.id)
                continue;
            var out = root.notificationList.slice();
            out[i] = root._entry(notif);
            root.notificationList = out;
            return;
        }
    }

    function _remove(id) {
        var out = [];
        for (var i = 0; i < root.notificationList.length; i++)
            if (root.notificationList[i].id !== id)
                out.push(root.notificationList[i]);
        if (out.length !== root.notificationList.length) {
            root.notificationList = out;
            if (out.length === 0)
                root.emptied();
        }
    }

    // Keep the live object under watch: app-requested closes and timeouts must
    // take the pill entry with them (a withdrawn notification at index 0 left
    // the pill showing something that no longer exists).
    function _track(notif) {
        if (root._serverNotifs[notif.id] === notif)
            return;
        root._serverNotifs[notif.id] = notif;
        notif.closed.connect(function (reason) {
            delete root._serverNotifs[notif.id];
            root._remove(notif.id);
        });
        notif.summaryChanged.connect(function () {
            root._sync(notif);
        });
        notif.bodyChanged.connect(function () {
            root._sync(notif);
        });
        notif.appNameChanged.connect(function () {
            root._sync(notif);
        });
        notif.appIconChanged.connect(function () {
            root._sync(notif);
        });
        notif.imageChanged.connect(function () {
            root._sync(notif);
        });
        notif.urgencyChanged.connect(function () {
            root._sync(notif);
        });
    }

    function dismiss(id) {
        if (root._serverNotifs[id]) {
            root._serverNotifs[id].dismiss();
            delete root._serverNotifs[id];
        }
        root._remove(id);
    }

    function clear() {
        // snapshot first: dismiss() emits closed, which mutates the map
        var ids = [];
        for (var id in root._serverNotifs)
            ids.push(id);
        for (var i = 0; i < ids.length; i++) {
            try {
                root._serverNotifs[ids[i]].dismiss();
            } catch (e) { /* already closed */ }
        }
        root._serverNotifs = {};
        var had = root.notificationList.length > 0;
        root.notificationList = [];
        if (had)
            root.emptied();
    }

    function _add(notif) {
        var entry = root._entry(notif);

        // Same server id already listed (reload replay): refresh in place.
        for (var i = 0; i < root.notificationList.length; i++) {
            if (root.notificationList[i].id === entry.id) {
                root._sync(notif);
                return;
            }
        }

        // Same content under a new id: promote the fresh entry instead of
        // dropping it, or the pill keeps showing the older copy.
        for (var j = 0; j < root.notificationList.length; j++) {
            var n = root.notificationList[j];
            if (n.summary !== entry.summary || n.body !== entry.body || n.appName !== entry.appName)
                continue;
            var rest = root.notificationList.slice();
            rest.splice(j, 1);
            root.notificationList = [entry, ...rest];
            return;
        }

        var list = [entry, ...root.notificationList];
        var limit = Config.maxNotifications;
        if (list.length > limit)
            list = list.slice(0, limit);
        root.notificationList = list;
    }

    // Apps play their own notification sounds via libcanberra's event-sounds.
    // Mute them through gsettings so DND silences sound too. ponytail: only
    // covers GTK/canberra-originated sounds; Electron/Discord-style apps that
    // play their own clips ignore it.
    onDoNotDisturbChanged: _syncSound()

    // DND isn't persisted, so restart flips doNotDisturb back to false; keep
    // sounds consistent with the tile instead of leaving them silently muted.
    Component.onCompleted: _syncSound()

    function _syncSound() {
        dndSoundCmd.command = ["gsettings", "set", "org.gnome.desktop.sound", "event-sounds", root.doNotDisturb ? "false" : "true"];
        dndSoundCmd.run();
    }

    Cmd {
        id: dndSoundCmd
        autorun: false
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        property bool ready: false
        Component.onCompleted: Qt.callLater(function () {
            server.ready = true;
        })

        onNotification: notif => {
            notif.tracked = true;
            root._track(notif);
            root._add(notif);
            if (server.ready)
                root.received();
        }
    }
}
