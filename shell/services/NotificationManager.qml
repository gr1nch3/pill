pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property var notificationList: []
    property bool doNotDisturb: false
    // Maps our entry ids (the notification daemon's id) to the live server
    // Notification object so remove()/clear() can dismiss (send
    // NotificationClosed) instead of just hiding the pill copy.
    property var _serverNotifs: ({})

    // Apps play their own notification sounds via libcanberra's event-sounds.
    // Mute them through gsettings so DND silences sound too. ponytail: only
    // covers GTK/canberra-originated sounds; Electron/Discord-style apps that
    // play their own clips ignore it.
    onDoNotDisturbChanged: {
        dndSoundProc.command = ["gsettings", "set", "org.gnome.desktop.sound", "event-sounds",
            root.doNotDisturb ? "false" : "true"]
        dndSoundProc.running = true
    }

    Process {
        id: dndSoundProc
        command: []
        running: false
    }

    // DND isn't persisted, so restart flips doNotDisturb back to false; keep
    // sounds consistent with the tile instead of leaving them silently muted.
    Component.onCompleted: {
        dndSoundProc.command = ["gsettings", "set", "org.gnome.desktop.sound", "event-sounds",
            root.doNotDisturb ? "false" : "true"]
        dndSoundProc.running = true
    }

    function trackServer(notif) {
        root._serverNotifs[notif.id] = notif
    }

    function add(summary, body, appName, id, appIcon, image, urgency) {
        // Don't add duplicates (same id already in the list)
        for (var i = 0; i < root.notificationList.length; i++) {
            var n = root.notificationList[i]
            if (n.id === id) return
        }

        // Content-based dedup (catches hot-reload replays with different IDs)
        for (var i = 0; i < root.notificationList.length; i++) {
            var n = root.notificationList[i]
            if (n.summary === (summary || "") && n.body === (body || "") && n.appName === (appName || "")) return
        }

        // Prepend so newest is first
        var entry = {
            summary: summary || "",
            body: body || "",
            appName: appName || "",
            appIcon: appIcon || "",
            image: image || "",
            urgency: urgency || 1,
            id: id
        }
        var list = [entry, ...root.notificationList]
        var limit = Config.maxNotifications
        if (list.length > limit) {
            list = list.slice(0, limit)
        }
        root.notificationList = list
    }

    function remove(index) {
        var entry = root.notificationList[index]
        if (entry && root._serverNotifs[entry.id]) {
            root._serverNotifs[entry.id].dismiss()
            delete root._serverNotifs[entry.id]
        }
        root.notificationList = root.notificationList.filter(function(_, i) { return i !== index })
    }

    function clear() {
        var list = root.notificationList.slice()
        for (var i = 0; i < list.length; i++) {
            var n = list[i]
            if (root._serverNotifs[n.id]) {
                try {
                    root._serverNotifs[n.id].dismiss()
                } catch (e) { /* already closed */ }
            }
        }
        root._serverNotifs = {}
        root.notificationList = []
    }
}
