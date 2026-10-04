pragma Singleton
// Owns the notification server and the pill's copy of the list. Callers use
// dismiss(id)/clear(); no field marshalling, no list indexes.
import QtQuick
import Quickshell.Services.Notifications

import "../utils"

Item {
    id: root

    property var notificationList: []
    property bool doNotDisturb: false

    // Emitted for a new notification once the server is past boot replay;
    // shell.qml decides whether to show the pill.
    signal received

    // Maps entry ids to the live server objects so dismiss/clear actually
    // close them (NotificationClosed), not just hide the pill copy.
    property var _serverNotifs: ({})

    function dismiss(id) {
        var entry = null
        var out = []
        for (var i = 0; i < root.notificationList.length; i++) {
            var n = root.notificationList[i]
            if (n.id === id) entry = n
            else out.push(n)
        }
        if (!entry) return
        if (root._serverNotifs[id]) {
            root._serverNotifs[id].dismiss()
            delete root._serverNotifs[id]
        }
        root.notificationList = out
    }

    function clear() {
        for (var id in root._serverNotifs) {
            try { root._serverNotifs[id].dismiss() } catch (e) { /* already closed */ }
        }
        root._serverNotifs = {}
        root.notificationList = []
    }

    function _add(notif) {
        var summary = notif.summary || ""
        var body = notif.body || ""
        var appName = notif.appName || ""
        var id = notif.id

        // Don't add duplicates (same id already in the list)
        for (var i = 0; i < root.notificationList.length; i++)
            if (root.notificationList[i].id === id) return

        // Content-based dedup (catches hot-reload replays with different IDs)
        for (var j = 0; j < root.notificationList.length; j++) {
            var n = root.notificationList[j]
            if (n.summary === summary && n.body === body && n.appName === appName) return
        }

        var entry = {
            summary: summary,
            body: body,
            appName: appName,
            appIcon: notif.appIcon || "",
            image: notif.image || "",
            urgency: notif.urgency || 1,
            id: id
        }
        var list = [entry, ...root.notificationList]
        var limit = Config.maxNotifications
        if (list.length > limit) list = list.slice(0, limit)
        root.notificationList = list
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
        dndSoundCmd.command = ["gsettings", "set", "org.gnome.desktop.sound", "event-sounds",
            root.doNotDisturb ? "false" : "true"]
        dndSoundCmd.run()
    }

    Cmd { id: dndSoundCmd; autorun: false }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        property bool ready: false
        Component.onCompleted: Qt.callLater(function() { server.ready = true })

        onNotification: (notif) => {
            notif.tracked = true
            root._serverNotifs[notif.id] = notif
            root._add(notif)
            if (server.ready) root.received()
        }
    }
}
