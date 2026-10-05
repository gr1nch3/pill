pragma Singleton
// Wallpaper library + renderer: scans the library (images, animated gifs,
// videos), generates thumbnails, and renders through awww/mpvpaper. Wallust
// runs here on each change (palette + user templates); ThemeController only
// reloads the palette afterwards. Video wallpapers require mpvpaper
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
    readonly property string _configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string _cacheHome: Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")
    readonly property string _wallustConfig: _configHome + "/wallust/wallust.toml"
    // wallust's --save-scheme names its output after the input file. Bubbles
    // analyses a stable cache copy, so the generated scheme has a fixed name
    // that cannot collide with a wallpaper-derived one in the user's
    // ~/.config/wallust/colorschemes/ directory.
    readonly property string _wallustSource: _cacheHome + "/bubbles/wallust-source.jpg"
    readonly property string _wallustSavedDir: _configHome + "/wallust/colorschemes"
    readonly property string _wallustSaved: _wallustSavedDir + "/wallust-source.json"

    property string committedWallpaper: ""
    readonly property string currentWallpaper: committedWallpaper

    property string pendingWallpaper: ""
    property string applyingWallpaper: ""
    property string applyingKind: "image"
    property bool _regeneratePending: false
    property bool _retint: true
    property int _lastTransition: -1

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

    // ── Lock / sign-in background ──────────────────────────────────────────
    // The lock target is the user's explicit lock wallpaper when set, else the
    // desktop one. One bounded still (lock-frame.jpg) is derived for images,
    // gifs and videos; a gif is additionally copied whole so the greeter can
    // animate it. The lock screen animates gifs and shows video stills;
    // `bubbles greeter` installs the files for SDDM.
    readonly property string lockTarget: Config.lockWallpaperPath !== ""
        ? Config.lockWallpaperPath : committedWallpaper
    readonly property string lockFramePath: (Quickshell.env("XDG_CACHE_HOME")
        || (Quickshell.env("HOME") + "/.cache")) + "/bubbles/lock-frame.jpg"
    readonly property string greeterGifPath: (Quickshell.env("XDG_CACHE_HOME")
        || (Quickshell.env("HOME") + "/.cache")) + "/bubbles/greeter-wallpaper.gif"
    property string lockFrameFor: ""
    property int _lockFrameSeq: 0
    property bool _lockFramePending: false

    readonly property string lockKind: lockTarget ? _kindOf(lockTarget) : ""

    readonly property string lockSource: {
        if (!lockTarget) return ""
        if (_kindOf(lockTarget) === "image") return lockTarget
        if (lockFrameFor === lockTarget) return lockFramePath + "?" + _lockFrameSeq
        return _thumbOf(lockTarget)
    }

    Connections {
        target: Config
        function onLockWallpaperPathChanged() { root._refreshLockFrame() }
    }

    function _refreshLockFrame() {
        if (!lockTarget) return
        if (!Integrations.ready) {
            if (_lockFramePending) return
            _lockFramePending = true
            Integrations.whenReady(function() { root._lockFramePending = false; root._refreshLockFrame() })
            return
        }
        if (!Integrations.has("magick")) return
        var kind = _kindOf(lockTarget)
        var out = Sh.q(root.lockFramePath)
        var src = Sh.q(lockTarget)
        var extract
        if (kind === "video" && Integrations.has("ffmpegthumbnailer"))
            extract = "ffmpegthumbnailer -i " + src + " -o " + out + " -s 1920 -a"
        else if (kind === "video")
            extract = "ffmpeg -v error -y -i " + src +
                " -vf 'scale=1920:1920:force_original_aspect_ratio=increase,crop=1920:1080' -frames:v 1 " + out
        else
            extract = "magick " + src + (kind === "gif" ? "[0]" : "") +
                " -resize 1920x1920^ -gravity center -extent 1920x1080 -quality 88 " + out
        // The greeter picks its background by file: gifs get the animation,
        // everything else the bounded still. Exactly one must exist after the
        // push, so remove the other here.
        var background = kind === "gif"
            ? "cp " + src + " " + Sh.q(root.greeterGifPath)
            : "rm -f " + Sh.q(root.greeterGifPath)
        lockFrameCmd.command = ["bash", "-c",
            "mkdir -p " + Sh.q(root.cacheDir) + " && { " + extract + "; } 2>/dev/null || true\n" +
            background + "\n"]
        lockFrameCmd.run()
    }

    Cmd {
        id: lockFrameCmd
        autorun: false
        onDone: {
            root.lockFrameFor = root.lockTarget
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

    // One random draw per change: wipes at any angle, a wavy sweep, a cursor
    // or random bloom, an inward close, or a crossfade. Beziers and durations
    // are tuned per family so every draw settles cleanly; an immediate repeat
    // steps to the next entry instead.
    function _imageCommand(path) {
        function rnd(n) { return Math.floor(Math.random() * n) }
        var angles = [0, 45, 90, 135, 180, 225, 270, 315]
        var opts = [
            "--transition-type wipe --transition-angle " + angles[rnd(8)] +
                " --transition-duration 0.9 --transition-bezier 0.65,0,0.35,1",
            "--transition-type wave --transition-angle " + angles[rnd(8)] +
                " --transition-wave " + ["12,12", "20,20", "32,32"][rnd(3)] +
                " --transition-duration 1.1 --transition-bezier 0.5,0,0.2,1",
            "--transition-type grow --transition-pos \"$pos\" --invert-y" +
                " --transition-duration 1.1 --transition-bezier 0.22,1,0.36,1",
            "--transition-type outer --transition-pos \"$pos\" --invert-y" +
                " --transition-duration 1.0 --transition-bezier 0.22,1,0.36,1",
            "--transition-type any --transition-duration 1.0 --transition-bezier 0.22,1,0.36,1",
            "--transition-type center --transition-duration 1.0 --transition-bezier 0.22,1,0.36,1",
            "--transition-type fade --transition-duration 1.0 --transition-bezier 0.4,0,0.2,1"
        ]
        var pick = rnd(opts.length)
        if (pick === root._lastTransition) pick = (pick + 1) % opts.length
        root._lastTransition = pick
        var transition = opts[pick]

        var script =
            "pkill -x mpvpaper 2>/dev/null || true\n" +
            // Render one frame per vblank: over-rendering drops frames and
            // competes with the compositor on the CPU; 60 is the floor.
            "fps=$(hyprctl -j monitors 2>/dev/null | jq -r '[.[].refreshRate // 60] | max | round' 2>/dev/null)\n" +
            "case \"$fps\" in ''|*[!0-9]*) fps=60 ;; esac\n"
        if (transition.indexOf("$pos") !== -1)
            script += "pos=$(hyprctl cursorpos 2>/dev/null | grep -E '^-?[0-9]+, ?-?[0-9]+$' | tr -d ' ')\n" +
                "[ -z \"$pos\" ] && pos=center\n"
        script += "exec awww img -a " + Sh.q(path) + " " + transition + " --transition-fps \"$fps\""
        return ["bash", "-c", script]
    }

    // ponytail: one wallust script builder. It generates an aspect-preserving
    // 512px still at a stable path (so --save-scheme has a fixed name that
    // cannot collide with a wallpaper-derived one), then wallust applies the
    // user's templates itself and writes the full colourscheme for ThemeEngine
    // to read. persistPath writes wallpaper.txt, null skips it.
    function _wallustScript(path, persistPath) {
        var script =
            "mkdir -p " + Sh.q(root._stateDir) + " " +
                Sh.q(root._cacheHome + "/bubbles") + " " + Sh.q(root._wallustSavedDir) + "\n" +
            "rm -f " + Sh.q(root._wallustSource) + "\n" +
            root._stillCommand(_kindOf(path), path) + "\n" +
            "wallust run " + Sh.q(root._wallustSource) + " -q --save-scheme\n" +
            "jq -c . " + Sh.q(root._wallustSaved) + " > " + Sh.q(ThemeEngine.schemePath + ".tmp") + " && mv " +
                Sh.q(ThemeEngine.schemePath + ".tmp") + " " + Sh.q(ThemeEngine.schemePath) + "\n" +
            "rm -f " + Sh.q(root._wallustSaved) + "\n";
        if (persistPath)
            script += "printf '%s' " + Sh.q(persistPath) + " > " + Sh.q(root._wallpaperPath) + "\n";
        return script;
    }

    // A bounded, aspect-preserving still for wallust to analyse: the whole
    // image counts (gifs take their first frame, videos a frame), not just a
    // centre crop. Writes root._wallustSource; a failure leaves it absent.
    function _stillCommand(kind, path) {
        var out = Sh.q(root._wallustSource)
        if (kind === "gif")
            return "magick " + Sh.q(path) + "[0] -resize 512x512 " + out + " 2>/dev/null || true"
        if (kind === "video")
            return "ffmpegthumbnailer -i " + Sh.q(path) + " -o " + out + " -s 512 -a 2>/dev/null || " +
                "ffmpeg -v error -y -i " + Sh.q(path) + " -vf 'scale=512:-2' -frames:v 1 " + out + " 2>/dev/null || true"
        return "magick " + Sh.q(path) + " -resize 512x512 " + out + " 2>/dev/null || true"
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
                Qt.callLater(function() { root.regenerate() });
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

    // retint=false renders + persists only: a fixed theme is active and the
    // palette must not follow the wallpaper. Defaults to true.
    function set(path, retint) {
        if (!path) {
            console.warn("Wallpaper.set called with empty path")
            return
        }

        var kind = _kindOf(path)
        if (kind === "video" && !Integrations.canVideoWallpaper) {
            console.warn("Wallpaper: mpvpaper is not installed — video wallpaper refused")
            return
        }

        root._retint = retint === undefined ? true : retint
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

        if (root._retint) {
            applyCmd.command = ["bash", "-c",
                root._wallustScript(root.applyingWallpaper, applyingWallpaper)];
        } else {
            // Persist the path for login resume; leave the palette alone.
            applyCmd.command = ["bash", "-c",
                "mkdir -p " + Sh.q(root._stateDir) + "\n" +
                "printf '%s' " + Sh.q(applyingWallpaper) + " > " + Sh.q(root._wallpaperPath)];
        }
        applyCmd.run();
    }

    function regenerate() {
        if (!root.committedWallpaper) {
            console.warn("Wallpaper.regenerate called with no current wallpaper")
            return
        }

        if (applyCmd.running) {
            root._regeneratePending = true
            return
        }

        root.applyingWallpaper = root.committedWallpaper;
        root._regeneratePending = false;

        applyCmd.command = ["bash", "-c",
            root._wallustScript(root.committedWallpaper, null)];
        applyCmd.run();
    }

    // ── wallust template count (Settings → Integrations) ──────────────────
    property int templateCount: 0

    Cmd {
        id: templateCountCmd
        command: ["bash", "-c",
            "awk '/^\\[/{s=($0==\"[templates]\")} s && /^[^#\\[]/ {sub(/[.=].*/,\"\"); print}' " +
            Sh.q(root._wallustConfig) + " 2>/dev/null | sort -u | wc -l"]
        autorun: false
        onLine: function(line) { root.templateCount = parseInt(line.trim()) || 0 }
    }

    function refreshTemplateCount() {
        templateCountCmd.run()
    }
}
