pragma Singleton
// Central registry for every external binary Pill shells out to.
//
// One probe at startup; everything else asks `has()` / the capability flags
// instead of firing commands that silently die with 127 on a machine that
// lacks the tool. `pill doctor` matches this list.
import QtQuick

import "../utils"
import "../utils/shquote.js" as Sh

Item {
    id: root

    // Single-provider tools, by area. Interchangeable picks live in toolGroups
    // below; the probe list (`known`) is derived from both.
    readonly property var soloKnown: [
        // theming
        "wallust", "gsettings", "fastfetch",
        // images / wallpapers
        "magick", "awww", "jq",
        // capture
        "grim", "slurp", "wf-recorder", "wl-copy", "cliphist",
        // video wallpapers
        "mpvpaper",
        // desktop plumbing
        "xdg-open", "xdg-mime", "pkill", "systemctl", "loginctl", "powerprofilesctl",
        // system config
        "timedatectl", "localectl", "pkexec", "gdbus", "getent", "useradd", "userdel",
        // hardware / session
        "brightnessctl", "nmcli", "pactl", "rfkill", "playerctl", "cava", "lspci", "free", "uname",
        // device management (optional; buttons are inert without)
        "nm-connection-editor", "blueman-manager",
        // compositor (optional; shell stays inert without it)
        "hyprctl"]

    // Interchangeable providers: any one installed satisfies the group. The
    // settings page and `pill doctor` render these once instead of flagging
    // every absent alternative (kitty installed -> foot/alacritty stay quiet).
    readonly property var toolGroups: [
        {
            label: "terminal",
            tools: ["kitty", "foot", "alacritty"]
        },
        {
            label: "annotator",
            tools: ["satty", "swappy"]
        },
        {
            label: "video thumbnails",
            tools: ["ffmpegthumbnailer", "ffmpeg"]
        },
        {
            label: "idle daemon",
            tools: ["hypridle", "swayidle"]
        }
    ]

    // What the startup probe checks: soloKnown plus every group alternative.
    // Deriving it keeps group membership in one place.
    readonly property var known: {
        var out = soloKnown.slice();
        for (var g = 0; g < toolGroups.length; g++)
            out = out.concat(toolGroups[g].tools);
        return out;
    }

    function groupProviders(group) {
        var out = [];
        for (var i = 0; i < group.tools.length; i++)
            if (has(group.tools[i]))
                out.push(group.tools[i]);
        return out;
    }

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

    // The region picker: slurp reads a predefined-box list from a non-tty
    // stdin and blocks forever on the pipe Quickshell hands children, so
    // `</dev/null` (EOF) selects interactive mode. Skin it from the live
    // palette — dark scrim, accent border, faint fill, dimensions label.
    // Colors stay quoted: a bare #hex would start a shell comment.
    function _hex(c) {
        function byte(x) {
            var s = Math.round(x * 255).toString(16);
            return s.length < 2 ? "0" + s : s;
        }
        return "#" + byte(c.r) + byte(c.g) + byte(c.b) + byte(c.a);
    }
    readonly property string slurpStyled: {
        var accent = ThemeController.accent;
        var scrim = Qt.rgba(ThemeController.background.r, ThemeController.background.g, ThemeController.background.b, 0.55);
        var fill = Qt.rgba(accent.r, accent.g, accent.b, 0.13);
        return "slurp </dev/null -b '" + _hex(scrim) + "' -c '" + _hex(accent) + "' -s '" + _hex(fill) + "' -d";
    }

    // Video wallpapers render through mpvpaper; gifs are handled by awww
    // natively. Thumbnails need ffmpegthumbnailer or ffmpeg.
    readonly property bool canVideoWallpaper: has("mpvpaper")
    readonly property bool canVideoThumbs: has("ffmpegthumbnailer") || has("ffmpeg")

    // dest: "save" | "clipboard" | "both"
    function shotCommand(mode, dest, filepath) {
        if (!canScreenshot)
            return [];
        var mkdir = "mkdir -p " + Sh.q(Config.screenshotDir) + " && ";
        var src = (mode !== "output" && canRegion) ? "-g \"$(" + slurpStyled + ")\" " : "";
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

    readonly property var regionPickerCommand: canRegion ? ["sh", "-c", "mkdir -p " + Sh.q(Config.recordingDir) + " && exec " + slurpStyled] : []

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
