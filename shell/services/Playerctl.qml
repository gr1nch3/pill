pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property string musicTitle: ""
    property string musicArtist: ""
    property string musicArt: ""
    property string musicUrl: ""
    property string playerName: ""
    property bool musicPlaying: false
    // Resolved album art: falls back to YouTube thumbnail from xesam:url
    readonly property string musicArtResolved: {
        if (root.musicArt)
            return root.musicArt;
        if (root.musicUrl) {
            var match = root.musicUrl.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/);
            if (match)
                return "https://img.youtube.com/vi/" + match[1] + "/hqdefault.jpg";
        }
        return "";
    }

    // ponytail: triple-bar delimiter. JS split keeps empty fields with a
    // multi-char delimiter, and "|||" is far less likely in a title than "|".
    readonly property string _fmt: "{{status}}|||{{title}}|||{{artist}}|||{{mpris:artUrl}}|||{{playerName}}|||{{xesam:url}}"

    function applyLine(line) {
        if (line === "STOPPED") {
            root.musicTitle = "";
            root.musicArtist = "";
            root.musicArt = "";
            root.musicUrl = "";
            root.playerName = "";
            root.musicPlaying = false;
            return;
        }
        var parts = line.split("|||");
        if (parts.length >= 6) {
            root.musicPlaying = parts[0] === "Playing";
            root.musicTitle = parts[1] || "";
            root.musicArtist = parts[2] || "";
            root.musicArt = parts[3] || "";
            root.playerName = parts[4] || "";
            root.musicUrl = parts[5] || "";
        }
    }

    // One-shot initial fetch: picks any Playing player across all players.
    Process {
        id: metadataProc
        command: ["bash", "-c", "result=$(playerctl -a metadata --format '" + root._fmt + "' 2>/dev/null | grep '^Playing' | head -1); " + "if [ -n \"$result\" ]; then echo \"$result\"; else echo 'STOPPED'; fi"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                root.applyLine(line);
            }
        }
    }

    // Event-driven: --follow blocks and re-emits the metadata line whenever the
    // most recently updated player changes. The 5s poll below is the safety
    // net for the "no player at boot" case, when follow exits immediately.
    // Both pause while the bar is hidden (root.active).
    Process {
        id: followProc
        command: ["playerctl", "-a", "--follow", "metadata", "--format", root._fmt]
        running: root.active
        stdout: SplitParser {
            onRead: function (line) {
                root.applyLine(line);
            }
        }
    }
    property bool active: true
    Timer {
        interval: 5000
        running: root.active
        repeat: true
        onTriggered: metadataProc.running = true
    }

    // ── Control helpers ────────────────────────────────────────────────────
    Process {
        id: prevProc
        command: ["playerctl", "previous"]
        running: false
    }
    Process {
        id: nextProc
        command: ["playerctl", "next"]
        running: false
    }
    Process {
        id: playProc
        command: ["playerctl", "play-pause"]
        running: false
    }
    Process {
        id: shuffleProc
        command: ["playerctl", "shuffle", "toggle"]
        running: false
    }
    Process {
        id: loopProc
        command: ["playerctl", "loop", "toggle"]
        running: false
    }

    function previous() {
        prevProc.running = true;
    }
    function next() {
        nextProc.running = true;
    }
    function shuffle() {
        shuffleProc.running = true;
    }
    function toggleLoop() {
        loopProc.running = true;
    }
    function playPause() {
        playProc.running = true;
        root.musicPlaying = !root.musicPlaying;
    }
}
