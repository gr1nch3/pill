pragma Singleton
// Local user accounts via getent passwd + org.freedesktop.Accounts
// (AccountsService owns display names/avatars). Current-user profile edits go
// through AccountsService; create/delete fall back to pkexec useradd/userdel.
import QtQuick
import Quickshell.Io

import "../utils/shquote.js" as Sh

Item {
    id: root

    // [{ name, uid, gecos, shell, realName, icon, current }]
    property var users: []
    property string currentUser: ""
    property int currentUid: -1
    property string lastError: ""
    property bool loading: false

    // scans accumulate here; users is assigned once per refresh (a per-line
    // slice+sort+assign re-rendered the whole account list per getent line)
    property var _userBuf: []

    readonly property bool available: Integrations.has("getent")

    function refresh() {
        if (!available)
            return;
        loading = true;
        users = [];
        _userBuf = [];
        listProc.running = true;
    }

    function current() {
        for (var i = 0; i < users.length; i++)
            if (users[i].current)
                return users[i];
        return null;
    }

    function _unwrap(s) {
        var i = String(s).indexOf("<'");
        var j = String(s).lastIndexOf("'>");
        return (i >= 0 && j > i) ? String(s).slice(i + 2, j) : "";
    }

    function setRealName(realName) {
        if (currentUid < 0 || realName === "")
            return false;
        if (realName.indexOf("'") !== -1) {
            lastError = "quotes are not supported";
            return false;
        }
        return _gdbus("SetUserName", realName);
    }

    function setIcon(path) {
        if (currentUid < 0 || path === "")
            return false;
        if (path.indexOf("'") !== -1) {
            lastError = "quotes are not supported";
            return false;
        }
        return _gdbus("SetIconFile", path);
    }

    function _gdbus(method, value) {
        lastError = "";
        if (!Integrations.has("gdbus")) {
            lastError = "gdbus missing";
            return false;
        }
        writeProc.command = ["bash", "-c", "gdbus call --system --dest org.freedesktop.Accounts " + "--object-path /org/freedesktop/Accounts/User" + currentUid + " " + "--method org.freedesktop.Accounts.User." + method + " " + Sh.q(value) + " && echo OK"];
        writeProc.running = true;
        return true;
    }

    function validUsername(name) {
        return /^[a-z][a-z0-9_-]{2,31}$/.test(name);
    }

    function addUser(username, fullName) {
        lastError = "";
        if (!validUsername(username)) {
            lastError = "invalid username";
            return false;
        }
        if (!Integrations.has("pkexec")) {
            lastError = "pkexec missing";
            return false;
        }
        writeProc.command = ["pkexec", "useradd", "-m", "-c", fullName || username, "-s", "/bin/bash", username];
        writeProc.running = true;
        return true;
    }

    function removeUser(username) {
        lastError = "";
        if (username === currentUser) {
            lastError = "cannot remove the current user";
            return false;
        }
        if (!Integrations.has("pkexec")) {
            lastError = "pkexec missing";
            return false;
        }
        writeProc.command = ["pkexec", "userdel", "-r", username];
        writeProc.running = true;
        return true;
    }

    function openPasswordTerminal(username) {
        var term = Integrations.terminalCommand(["pkexec", "passwd", username]);
        if (!term || term.length === 0) {
            lastError = "no terminal emulator found";
            return false;
        }
        writeProc.command = term;
        writeProc.running = true;
        return true;
    }

    Process {
        id: writeProc
        command: []
        running: false
        onExited: root.refresh()
    }

    // The registry probe can finish after our first refresh attempt.
    Connections {
        target: Integrations
        function onReadyChanged() {
            if (Integrations.ready && root.users.length === 0 && !root.loading)
                root.refresh();
        }
    }

    Process {
        id: listProc
        command: ["bash", "-c", "me=$(id -un); meuid=$(id -u)\n" + "printf 'CURRENT\\t%s\\t%s\\n' \"$me\" \"$meuid\"\n" + "getent passwd | awk -F: '$3>=1000 && $3<65534 {print $1\"\\t\"$3\"\\t\"$5\"\\t\"$7}' | " + "while IFS=$'\\t' read -r name uid gecos shell; do\n" + "  real=$(gdbus call --system --dest org.freedesktop.Accounts " + "--object-path /org/freedesktop/Accounts/User$uid " + "--method org.freedesktop.DBus.Properties.Get org.freedesktop.Accounts.User RealName 2>/dev/null)\n" + "  icon=$(gdbus call --system --dest org.freedesktop.Accounts " + "--object-path /org/freedesktop/Accounts/User$uid " + "--method org.freedesktop.DBus.Properties.Get org.freedesktop.Accounts.User IconFile 2>/dev/null)\n" + "  printf 'USER\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$name\" \"$uid\" \"$gecos\" \"$shell\" \"$real\" \"$icon\"\n" + "done"]
        running: false
        stdout: SplitParser {
            onRead: function (line) {
                var p = line.split("\t");
                if (p[0] === "CURRENT" && p.length >= 3) {
                    root.currentUser = p[1];
                    root.currentUid = parseInt(p[2]) || -1;
                } else if (p[0] === "USER" && p.length >= 7) {
                    root._userBuf.push({
                        name: p[1],
                        uid: parseInt(p[2]) || 0,
                        gecos: p[3],
                        shell: p[4],
                        realName: root._unwrap(p[5]) || p[3] || p[1],
                        icon: root._unwrap(p[6]),
                        current: p[1] === root.currentUser
                    });
                }
            }
        }
        onExited: {
            var out = root._userBuf.slice();
            out.sort(function (a, b) {
                return a.uid - b.uid;
            });
            root.users = out;
            root._userBuf = [];
            root.loading = false;
        }
    }

    Component.onCompleted: root.refresh()
}
