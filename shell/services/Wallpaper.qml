pragma Singleton
// Wallpaper library + renderer: scans the library (images, animated gifs,
// videos), generates thumbnails, and renders through awww/mpvpaper. Matugen
// runs in ThemeController; this module renders what it is given and emits
// `applied(path)` when a render finishes. Video wallpapers require mpvpaper
// (Integrations.canVideoWallpaper); they are refused with a warning without it.
import QtQuick
import Quickshell

import "../utils"
import "../utils/shquote.js" as Sh

Item {
    id: root

    readonly property string _stateDir: ThemeEngine.stateDir + "/bubbles"
    readonly property string _legacyStateDir: ThemeEngine.stateDir + "/pill"
    readonly property string _wallpaperPath: _stateDir + "/wallpaper.txt"
    readonly property string _matugenConfig: Quickshell.env("HOME") + "/.config/matugen/config.toml"

    property string committedWallpaper: ""
    readonly property string currentWallpaper: committedWallpaper

    property string pendingWallpaper: ""
    property string applyingWallpaper: ""
    property string applyingKind: "image"
    property bool _regeneratePending: false
    property string _mode: "dark"
    property string _variant: "scheme-content"

    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/bubbles/thumbnails"
    readonly property string legacyCacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/pill/thumbnails"
    readonly property string wallpapersCachePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/bubbles/wallpapers.json"
    // [{ name, path, thumb, kind }] — kind: image | gif | video
    property var wallpapers: []
    property bool scanning: false
    property var _buffer: []

    signal applied(string path)

    // ── Library queries ────────────────────────────────────────────────────
    readonly property var kindCounts: {
        var counts = { all: 0, image: 0, gif: 0, video: 0 }
        for (var i = 0; i < root.wallpapers.length; i++) {
            var k = root.wallpapers[i].kind
            counts.all++
            if (counts[k] !== undefined) counts[k]++
        }
        return counts
    }

    function query(filter, kind) {
        var q = filter ? String(filter).trim().toLowerCase() : ""
        var out = []
        for (var i = 0; i < root.wallpapers.length; i++) {
            var w = root.wallpapers[i]
            if (q !== "" && w.name.toLowerCase().indexOf(q) === -1) continue
            if (kind && kind !== "all" && w.kind !== kind) continue
            out.push(w)
        }
        return out
    }

    function indexOf(path) {
        for (var i = 0; i < root.wallpapers.length; i++)
            if (root.wallpapers[i].path === path) return i
        return -1
    }

    // ── Library scan ───────────────────────────────────────────────────────
    Cmd {
        id: scanCmd
        command: []
        autorun: false
        onLine: function(line) {
            const parts = line.split("\t");
            if (parts.length < 4) return;
            root._buffer.push({
                name: parts[0],
                path: parts[1],
                thumb: parts[2],
                kind: parts[3]
            });
            // Progressive publish only for a cold (uncached) load; with a
            // cached list the scan updates in place at the end.
            if (root.wallpapers.length === 0 && root._buffer.length % 25 === 0)
                root.wallpapers = root._buffer.slice();
        }
        onDone: {
            var next = root._buffer
            root._buffer = []
            root.scanning = false
            // Keep the cached array (and coverflow position) when nothing
            // changed; only assign and persist on a real difference.
            if (!root._sameList(next, root.wallpapers)) {
                root.wallpapers = next
                cacheSaveCmd.command = ["sh", "-c", Store.saveCommand(root.wallpapersCachePath, JSON.stringify(next))]
                cacheSaveCmd.run()
            }
        }
    }

    function _sameList(a, b) {
        if (a.length !== b.length) return false
        for (var i = 0; i < a.length; i++)
            if (a[i].path !== b[i].path || a[i].thumb !== b[i].thumb || a[i].kind !== b[i].kind) return false
        return true
    }

    // Instant list on startup; refresh() still checks for new files.
    Cmd {
        id: cacheLoadCmd
        command: ["bash", "-c", Store.loadCommand(root.wallpapersCachePath, "")]
        autorun: false
        onLine: function(line) {
            var data = Store.parse(line)
            if (data && data.length !== undefined && root.wallpapers.length === 0)
                root.wallpapers = data
        }
    }

    Cmd { id: cacheSaveCmd; autorun: false }

    function refresh() {
        root._buffer = []
        scanCmd.command = ["bash", "-c",
            "if [ ! -d " + Sh.q(root.cacheDir) + " ] && [ -d " + Sh.q(root.legacyCacheDir) + " ]; then mv " +
                Sh.q(root.legacyCacheDir) + " " + Sh.q(root.cacheDir) + "; fi\n" +
            "mkdir -p " + Sh.q(root.cacheDir) + "\n" +
            "[ -f " + Sh.q(root._stateDir + "/hypr-scheme.conf") + " ] || " +
                "{ [ -f " + Sh.q(root._legacyStateDir + "/hypr-scheme.conf") + " ] && mv " +
                Sh.q(root._legacyStateDir + "/hypr-scheme.conf") + " " + Sh.q(root._stateDir + "/hypr-scheme.conf") + "; }\n" +
            "find " + Sh.q(Config.wallpaperDir) + " -maxdepth 1 -type f \\( " +
            "-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o " +
            "-iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' " +
            "\\) -print0 | while IFS= read -r -d '' f; do\n" +
            "  ext=\"${f##*.}\"; ext=\"$(printf '%s' \"$ext\" | tr 'A-Z' 'a-z')\"\n" +
            "  case \"$ext\" in\n" +
            "    gif) kind=gif ;;\n" +
            "    mp4|webm|mkv|mov) kind=video ;;\n" +
            "    *) kind=image ;;\n" +
            "  esac\n" +
            "  hash=\"$(printf 'v3:%s:%s' \"$kind\" \"$f\" | sha256sum | cut -d' ' -f1)\"\n" +
            "  thumb=" + Sh.q(root.cacheDir) + "/$hash.jpg\n" +
            "  if [ ! -f \"$thumb\" ]; then\n" +
            "    case \"$kind\" in\n" +
            "      gif) magick \"$f[0]\" -resize 512x512^ -gravity center -extent 512x512 \"$thumb\" 2>/dev/null || true ;;\n" +
            "      video) ffmpegthumbnailer -i \"$f\" -o \"$thumb\" -s 512 -a 2>/dev/null || " +
            "ffmpeg -v error -y -i \"$f\" -vf 'scale=512:512:force_original_aspect_ratio=increase,crop=512:512' -frames:v 1 \"$thumb\" 2>/dev/null || true ;;\n" +
            "      *) magick \"$f\" -resize 512x512^ -gravity center -extent 512x512 \"$thumb\" 2>/dev/null || true ;;\n" +
            "    esac\n" +
            "  fi\n" +
            "  printf '%s\\t%s\\t%s\\t%s\\n' \"$(basename \"$f\")\" \"$f\" \"$thumb\" \"$kind\"\n" +
            "done"
        ];
        root.scanning = true;
        scanCmd.run();
    }

    function _kindOf(path) {
        var ext = String(path).split(".").pop().toLowerCase()
        if (ext === "gif") return "gif"
        if (ext === "mp4" || ext === "webm" || ext === "mkv" || ext === "mov") return "video"
        return "image"
    }

    function _thumbOf(path) {
        for (var i = 0; i < wallpapers.length; i++)
            if (wallpapers[i].path === path) return wallpapers[i].thumb
        return ""
    }

    // ── Lock / sign-in still ───────────────────────────────────────────────
    // One bounded frame for the current wallpaper: images are resized, gifs and
    // videos take their first frame. The lock screen shows it (gifs animate via
    // AnimatedImage) and `bubbles greeter` installs it for SDDM.
    readonly property string lockFramePath: (Quickshell.env("XDG_CACHE_HOME")
        || (Quickshell.env("HOME") + "/.cache")) + "/bubbles/lock-frame.jpg"
    property string lockFrameFor: ""
    property int _lockFrameSeq: 0
    property bool _lockFramePending: false

    readonly property string lockKind: committedWallpaper ? _kindOf(committedWallpaper) : ""

    readonly property string lockSource: {
        if (!committedWallpaper) return ""
        if (_kindOf(committedWallpaper) === "image") return committedWallpaper
        if (lockFrameFor === committedWallpaper) return lockFramePath + "?" + _lockFrameSeq
        return _thumbOf(committedWallpaper)
    }

    function _refreshLockFrame() {
        if (!committedWallpaper) return
        if (!Integrations.ready) {
            if (_lockFramePending) return
            _lockFramePending = true
            Integrations.whenReady(function() { root._lockFramePending = false; root._refreshLockFrame() })
            return
        }
        if (!Integrations.has("magick")) return
        var kind = _kindOf(committedWallpaper)
        var out = Sh.q(root.lockFramePath)
        var src = Sh.q(committedWallpaper)
        var extract
        if (kind === "video" && Integrations.has("ffmpegthumbnailer"))
            extract = "ffmpegthumbnailer -i " + src + " -o " + out + " -s 1920 -a"
        else if (kind === "video")
            extract = "ffmpeg -v error -y -i " + src +
                " -vf 'scale=1920:1920:force_original_aspect_ratio=increase,crop=1920:1080' -frames:v 1 " + out
        else
            extract = "magick " + src + (kind === "gif" ? "[0]" : "") +
                " -resize 1920x1920^ -gravity center -extent 1920x1080 -quality 88 " + out
        lockFrameCmd.command = ["bash", "-c",
            "mkdir -p " + Sh.q(root.cacheDir) + " && { " + extract + "; } 2>/dev/null || true"]
        lockFrameCmd.run()
    }

    Cmd {
        id: lockFrameCmd
        autorun: false
        onDone: {
            root.lockFrameFor = root.committedWallpaper
            root._lockFrameSeq++
        }
    }

    // ── Persistence ────────────────────────────────────────────────────────
    Cmd {
        id: loadWpCmd
        command: ["bash", "-c",
            Store.migrateCommand(root._wallpaperPath, root._legacyStateDir + "/wallpaper.txt") +
            "cat " + Sh.q(root._wallpaperPath) + " 2>/dev/null || true"]
        autorun: false
        onLine: function(line) {
            const trimmed = line.trim()
            if (!trimmed) return
            root.committedWallpaper = trimmed
            Qt.callLater(root._resumeVideo)
            Qt.callLater(root._refreshLockFrame)
        }
    }

    // Re-start mpvpaper when the shell comes up on a video wallpaper. The
    // compositor autostart also calls setWallpaper via IPC; this covers a bare
    // `qs -p ...` launch.
    function _resumeVideo() {
        if (!committedWallpaper) return
        if (_kindOf(committedWallpaper) !== "video") return
        if (!Integrations.canVideoWallpaper) return
        if (awwwCmd.running) return
        awwwCmd.command = _videoCommand(committedWallpaper)
        awwwCmd.run()
    }

    // ── Rendering ──────────────────────────────────────────────────────────
    Cmd { id: awwwCmd; command: []; autorun: false }

    function _videoCommand(path) {
        return ["bash", "-c",
            "pkill -x mpvpaper 2>/dev/null || true\n" +
            "command -v awww >/dev/null 2>&1 && awww clear 000000 2>/dev/null || true\n" +
            "sleep 0.2\n" +
            "exec mpvpaper -o 'no-audio loop --hwdec=auto' ALL " + Sh.q(path)]
    }

    function _imageCommand(path) {
        return ["bash", "-c",
            "pkill -x mpvpaper 2>/dev/null || true\n" +
            "exec awww img -a " + Sh.q(path) +
            " --transition-type center --transition-angle 45 --transition-duration 1.5 --transition-fps 144"]
    }

    // ponytail: one matugen script builder. Images analyse directly; gifs and
    // videos analyse a still frame (the cached thumbnail, or one extracted on
    // demand). persistPath writes wallpaper.txt, null skips it.
    function _matugenScript(path, mode, variant, persistPath) {
        var kind = _kindOf(path)
        var pre = ""
        var srcExpr
        if (kind === "image") {
            srcExpr = Sh.q(path)
        } else {
            var thumb = _thumbOf(path)
            if (thumb !== "") {
                srcExpr = Sh.q(thumb)
            } else {
                // No scanned thumbnail yet: extract a frame inside the script.
                var frame = "frame=" + Sh.q(root.cacheDir) + "/theme-frame-$(printf '%s' " +
                    Sh.q(path) + " | sha256sum | cut -d' ' -f1).jpg\n"
                pre = frame +
                    "if [ ! -f \"$frame\" ]; then\n" +
                    (kind === "gif"
                        ? "  magick " + Sh.q(path) + "[0] -resize 512x512^ -gravity center -extent 512x512 \"$frame\" 2>/dev/null || true\n"
                        : "  ffmpegthumbnailer -i " + Sh.q(path) + " -o \"$frame\" -s 512 -a 2>/dev/null || " +
                          "ffmpeg -v error -y -i " + Sh.q(path) + " -vf 'scale=512:512:force_original_aspect_ratio=increase,crop=512:512' -frames:v 1 \"$frame\" 2>/dev/null || true\n") +
                    "fi\n"
                srcExpr = "\"$frame\""
            }
        }
        var script =
            pre +
            "mkdir -p " + Sh.q(root._stateDir) + "\n" +
            "mode=" + Sh.q(mode) + "\n" +
            "if [ \"$mode\" = 'auto' ]; then\n" +
            "  brightness=\"$(magick " + srcExpr + " -resize 1x1 -format '%[fx:int(100*mean)]' info:)\"\n" +
            "  if [ \"$brightness\" -gt " + Config.themeAutoThreshold + " ]; then mode='light'; else mode='dark'; fi\n" +
            "fi\n" +
            "matugen image " + srcExpr + " -m \"$mode\" -t " + Sh.q(variant) +
            " --prefer " + Sh.q(Config.themePrefer) + " -j hex > " + Sh.q(ThemeEngine.schemePath) + "\n";
        if (persistPath)
            script += "printf '%s' " + Sh.q(persistPath) + " > " + Sh.q(root._wallpaperPath) + "\n";
        return script;
    }

    Cmd {
        id: applyCmd
        command: []
        autorun: false
        onDone: {
            const applied = root.applyingWallpaper;
            root.applyingWallpaper = "";

            root.applied(applied);

            if (root._regeneratePending) {
                root._regeneratePending = false;
                Qt.callLater(function() { root.regenerate(root._mode, root._variant) });
            } else if (root.pendingWallpaper && root.pendingWallpaper !== applied) {
                Qt.callLater(root._startApply);
            }
        }
    }

    Component.onCompleted: {
        cacheLoadCmd.run()
        loadWpCmd.run()
        root.refreshTemplateCount()
        Integrations.whenReady(function() { root._resumeVideo() })
    }

    function set(path, mode, variant) {
        if (!path) {
            console.warn("Wallpaper.set called with empty path")
            return
        }

        var kind = _kindOf(path)
        if (kind === "video" && !Integrations.canVideoWallpaper) {
            console.warn("Wallpaper: mpvpaper is not installed — video wallpaper refused")
            return
        }

        root._mode = mode || root._mode
        root._variant = variant || root._variant
        committedWallpaper = path;
        pendingWallpaper = path;
        root._refreshLockFrame()
        if (!applyCmd.running)
            root._startApply();
    }

    function _startApply() {
        if (!pendingWallpaper || applyCmd.running)
            return;

        applyingWallpaper = pendingWallpaper;
        applyingKind = _kindOf(applyingWallpaper);

        if (applyingKind === "video") {
            awwwCmd.command = _videoCommand(applyingWallpaper);
        } else {
            awwwCmd.command = _imageCommand(applyingWallpaper);
        }
        // The previous renderer may still be running (mpvpaper never exits),
        // and run() only queues a re-run while running — stop first so the
        // new command actually starts (covers video -> image and video -> video).
        awwwCmd.stop();
        Qt.callLater(awwwCmd.run);

        applyCmd.command = ["bash", "-c",
            root._matugenScript(root.applyingWallpaper, root._mode, root._variant, applyingWallpaper)];
        applyCmd.run();
    }

    function regenerate(mode, variant) {
        if (!root.committedWallpaper) {
            console.warn("Wallpaper.regenerate called with no current wallpaper")
            return
        }

        root._mode = mode || root._mode
        root._variant = variant || root._variant

        if (applyCmd.running) {
            root._regeneratePending = true
            return
        }

        root.applyingWallpaper = root.committedWallpaper;
        root._regeneratePending = false;

        applyCmd.command = ["bash", "-c",
            root._matugenScript(root.committedWallpaper, root._mode, root._variant, null)];
        applyCmd.run();
    }

    // ── Matugen template count (Settings → Integrations) ──────────────────
    property int templateCount: 0

    Cmd {
        id: templateCountCmd
        command: ["bash", "-c", "grep -c '^\\[templates\\.' " + Sh.q(root._matugenConfig) + " 2>/dev/null || true"]
        autorun: false
        onLine: function(line) { root.templateCount = parseInt(line.trim()) || 0 }
    }

    function refreshTemplateCount() {
        templateCountCmd.run()
    }
}
