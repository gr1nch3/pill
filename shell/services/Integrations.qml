pragma Singleton
// Central registry for every external binary Bubbles shells out to.
//
// One probe at startup; everything else asks `has()` / the capability flags
// instead of firing commands that silently die with 127 on a machine that
// lacks the tool. `bubbles doctor` matches this list.
import QtQuick
import Quickshell

import "../utils"
import "../utils/shquote.js" as Sh

Item {
    id: root

    readonly property var known: [
        // theming
        "wallust", "gsettings", "fastfetch",
        // images / wallpapers
        "magick", "awww", "jq",
        // capture
        "grim", "slurp", "wf-recorder", "satty", "swappy", "wl-copy", "cliphist",
        // media wallpapers
        "ffmpeg", "ffprobe", "ffmpegthumbnailer", "mpvpaper",
        // desktop plumbing
        "xdg-open", "xdg-mime", "pkill", "systemctl", "loginctl", "powerprofilesctl",
        // system config
        "timedatectl", "localectl", "pkexec", "gdbus", "getent", "useradd", "userdel",
        // terminals (password prompts)
        "kitty", "foot", "alacritty",
        // hardware / session
        "brightnessctl", "nmcli", "pactl", "rfkill", "playerctl", "cava", "lspci", "free", "uname",
        // device management + idle daemons (optional; buttons are inert without)
        "nm-connection-editor", "blueman-manager", "hypridle", "swayidle",
        // compositor (optional; shell stays inert without it)
        "hyprctl"]

    property var paths: ({})
    property bool ready: false

    function has(tool) {
        return !!paths[tool];
    }
    function path(tool) {
        return paths[tool] || "";
    }

    // Run cb once the probe has finished; callers that arrive early are queued.
    function whenReady(cb) {
        if (ready) {
            cb();
            return;
        }
        _readyCallbacks.push(cb);
    }
    property var _readyCallbacks: []

    // ── Capture capabilities ───────────────────────────────────────────────
    readonly property bool canScreenshot: has("grim")
    readonly property bool canRegion: has("slurp")
    readonly property bool canRecord: has("wf-recorder")
    readonly property bool canCopy: has("wl-copy")
    readonly property bool canClipboardHistory: has("cliphist")
    readonly property string annotator: has("satty") ? "satty" : (has("swappy") ? "swappy" : "")
    readonly property bool canAnnotate: annotator !== ""

    // Video wallpapers render through mpvpaper; gifs are handled by awww
    // natively. Thumbnails need ffmpegthumbnailer or ffmpeg.
    readonly property bool canVideoWallpaper: has("mpvpaper")
    readonly property bool canVideoThumbs: has("ffmpegthumbnailer") || has("ffmpeg")

    // dest: "save" | "clipboard" | "both"
    function shotCommand(mode, dest, filepath) {
        if (!canScreenshot)
            return [];
        var mkdir = "mkdir -p " + Sh.q(Config.screenshotDir) + " && ";
        var src = (mode !== "output" && canRegion) ? "-g \"$(slurp)\" " : "";
        var qpath = Sh.q(filepath);
        if (dest === "clipboard" && canCopy)
            return ["sh", "-c", mkdir + "grim " + src + "- | wl-copy"];
        if (dest === "both" && canCopy)
            return ["sh", "-c", mkdir + "grim " + src + qpath + " && wl-copy < " + qpath];
        return ["sh", "-c", mkdir + "grim " + src + qpath];
    }

    function recordingCommand(geometry, filepath) {
        if (!canRecord)
            return [];
        if (geometry)
            return ["wf-recorder", "-g", geometry, "-f", filepath];
        return ["sh", "-c", "mkdir -p " + Sh.q(Config.recordingDir) + " && exec wf-recorder -f " + Sh.q(filepath)];
    }

    readonly property var regionPickerCommand: canRegion ? ["sh", "-c", "mkdir -p " + Sh.q(Config.recordingDir) + " && exec slurp"] : []

    readonly property var recordPauseCommand: canRecord ? ["pkill", "-SIGUSR1", "wf-recorder"] : []
    readonly property var recordStopCommand: canRecord ? ["pkill", "-SIGINT", "wf-recorder"] : []

    function annotateCommand(filepath) {
        if (!canAnnotate)
            return [];
        return [annotator, "-f", filepath];
    }

    function copyCommand(filepath) {
        if (!canCopy)
            return [];
        return ["sh", "-c", "wl-copy < " + Sh.q(filepath)];
    }

    // Password prompts etc. need a tty; open the first terminal we know.
    function terminalCommand(args) {
        if (has("kitty"))
            return ["kitty"].concat(args);
        if (has("foot"))
            return ["foot"].concat(args);
        if (has("alacritty"))
            return ["alacritty", "-e"].concat(args);
        return [];
    }

    // ── Probe ──────────────────────────────────────────────────────────────
    readonly property string probeScript: {
        var list = [];
        for (var i = 0; i < known.length; i++)
            list.push(Sh.q(known[i]));
        return "for n in " + list.join(" ") + "; do p=$(command -v \"$n\" 2>/dev/null || true); " + "printf '%s=%s\\n' \"$n\" \"$p\"; done";
    }

    Cmd {
        id: probeCmd
        command: ["bash", "-c", root.probeScript]

        onLine: function (line) {
            var i = line.indexOf("=");
            if (i < 0)
                return;
            var next = {};
            for (var k in root.paths)
                next[k] = root.paths[k];
            next[line.slice(0, i)] = line.slice(i + 1);
            root.paths = next;
        }

        onDone: {
            root.ready = true;
            var cbs = root._readyCallbacks;
            root._readyCallbacks = [];
            for (var i = 0; i < cbs.length; i++)
                cbs[i]();
        }
    }
}
