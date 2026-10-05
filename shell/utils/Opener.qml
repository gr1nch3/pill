// One place that opens a folder/file in the user's session for settings pages.
pragma Singleton
import QtQuick

Item {
    id: root

    function path(p) {
        if (!p)
            return;
        cmd.command = ["xdg-open", p];
        cmd.run();
    }

    Cmd {
        id: cmd
        autorun: false
    }
}
