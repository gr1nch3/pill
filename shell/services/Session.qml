pragma Singleton
// Session actions over the Config.session* commands. Views name the action.
import QtQuick

import "../utils"

Item {
    id: root

    function run(action) {
        var cmd = _commands()[action];
        if (!cmd || cmd.length === 0)
            return;
        actionCmd.command = cmd;
        actionCmd.run();
    }

    function lock() {
        run("lock");
    }
    function logout() {
        run("logout");
    }
    function suspend() {
        run("suspend");
    }
    function shutdown() {
        run("shutdown");
    }
    function hibernate() {
        run("hibernate");
    }
    function reboot() {
        run("reboot");
    }

    function _commands() {
        return {
            lock: Config.sessionLock,
            logout: Config.sessionLogout,
            suspend: Config.sessionSuspend,
            shutdown: Config.sessionShutdown,
            hibernate: Config.sessionHibernate,
            reboot: Config.sessionReboot
        };
    }

    Cmd {
        id: actionCmd
        autorun: false
    }
}
