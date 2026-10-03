pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import "."
import "../components"
import "../utils/shquote.js" as Sh

Item {
    id: root

    readonly property string stateDir: ThemeEngine.stateDir + "/pill"
    readonly property string schemePath: ThemeEngine.schemePath
    readonly property string wallpaperPath: stateDir + "/wallpaper.txt"
    readonly property string matugenConfig: Quickshell.env("HOME") + "/.config/matugen/config.toml"

    property string committedWallpaper: ""

    readonly property string currentWallpaper: committedWallpaper

    property string pendingWallpaper: ""
    property string applyingWallpaper: ""
    property bool _regeneratePending: false

    // ── Directory scanning (merged from WallpaperDir) ────────────────────────
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/pill/thumbnails"
    property var wallpapers: []
    property bool scanning: false
    property var _buffer: []

    Process {
        id: scanProc
        command: []
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                const parts = line.split("\t");
                if (parts.length < 3) return;
                root._buffer.push({
                    name: parts[0],
                    path: parts[1],
                    thumb: parts[2]
                });
                // Publish progressively so huge libraries appear while scanning.
                if (root._buffer.length % 25 === 0)
                    root.wallpapers = root._buffer.slice();
            }
        }
        onExited: {
            root.wallpapers = root._buffer
            root._buffer = []
            root.scanning = false
        }
    }

    function refresh() {
        root._buffer = []
        scanProc.command = ["bash", "-c",
            "mkdir -p " + Sh.q(root.cacheDir) + "\n" +
            "find " + Sh.q(Config.wallpaperDir) + " -maxdepth 1 -type f \\( " +
            "-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' " +
            "\\) -print0 | while IFS= read -r -d '' f; do\n" +
            "  name=\"$(basename \"$f\")\"\n" +
            "  hash=\"$(printf 'v2:%s' \"$f\" | sha256sum | cut -d' ' -f1)\"\n" +
            "  thumb=" + Sh.q(root.cacheDir) + "/$hash.jpg\n" +
            "  if [ ! -f \"$thumb\" ]; then\n" +
            "    magick \"$f\" -resize 512x512^ -gravity center -extent 512x512 \"$thumb\" 2>/dev/null || true\n" +
            "  fi\n" +
            "  printf '%s\\t%s\\t%s\\n' \"$name\" \"$f\" \"$thumb\"\n" +
            "done"
        ];
        root.scanning = true;
        scanProc.running = true;
    }

    function query(filter) {
        if (!filter || filter.trim() === "")
            return wallpapers
        const q = filter.trim().toLowerCase()
        return wallpapers.filter(w => w.name.toLowerCase().includes(q))
    }

    Process { id: awwwProc; command: []; running: false }

    Process {
        id: loadWpProc
        command: ["cat", root.wallpaperPath]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                const trimmed = line.trim()
                if (trimmed) root.committedWallpaper = trimmed
            }
        }
    }

    Process {
        id: applyWpProc
        command: []
        running: false
        onExited: {
            const applied = root.applyingWallpaper;
            root.applyingWallpaper = "";

            ThemeEngine.load();
            root.refreshThemes();

            if (root._regeneratePending) {
                root._regeneratePending = false;
                Qt.callLater(root.regenerate);
            } else if (root.pendingWallpaper && root.pendingWallpaper !== applied) {
                Qt.callLater(root.startApply);
            }
        }
    }

    Process {
        id: applyThemesProc
        command: []
        running: false
    }

    Component.onCompleted: loadWpProc.running = true

    function set(path: string): void {
        if (!path) {
            console.warn("Wallpaper.set called with empty path")
            return
        }

        committedWallpaper = path;
        pendingWallpaper = path;
        if (!applyWpProc.running)
            startApply();
    }

    // ponytail: one matugen script builder. imageExpr is caller-quoted
    // (Sh.q(path), or "$tmpimg" for generated swatches); persistPath writes
    // wallpaper.txt, null skips it.
    function _matugenScript(imageExpr, mode, persistPath) {
        var script =
            "mkdir -p " + Sh.q(stateDir) + "\n" +
            "mode=" + Sh.q(mode) + "\n" +
            "if [ \"$mode\" = 'auto' ]; then\n" +
            "  brightness=\"$(magick " + imageExpr + " -resize 1x1 -format '%[fx:int(100*mean)]' info:)\"\n" +
            "  if [ \"$brightness\" -gt " + Config.themeAutoThreshold + " ]; then mode='light'; else mode='dark'; fi\n" +
            "fi\n" +
            "matugen image " + imageExpr + " -m \"$mode\" -t " + Theme.themeVariant +
            " --prefer " + Config.themePrefer + " -j hex > " + Sh.q(schemePath) + "\n";
        if (persistPath)
            script += "printf '%s' " + Sh.q(persistPath) + " > " + Sh.q(wallpaperPath) + "\n";
        return script;
    }

    function startApply(): void {
        if (!pendingWallpaper || applyWpProc.running)
            return;

        applyingWallpaper = pendingWallpaper;

        awwwProc.command = ["awww", "img", "-a", applyingWallpaper,
            "--transition-type", "center", "--transition-angle", "45",
            "--transition-duration", "1.5", "--transition-fps", "144"];
        awwwProc.running = true;

        applyWpProc.command = ["bash", "-c",
            root._matugenScript(Sh.q(applyingWallpaper), Theme.themeMode, applyingWallpaper)];
        applyWpProc.running = true;
    }

    function regenerate(): void {
        if (!root.committedWallpaper) {
            console.warn("Wallpaper.regenerate called with no current wallpaper")
            return
        }

        if (applyWpProc.running) {
            root._regeneratePending = true
            return
        }

        root.applyingWallpaper = root.committedWallpaper;
        root._regeneratePending = false;

        applyWpProc.command = ["bash", "-c",
            root._matugenScript(Sh.q(root.committedWallpaper), Theme.themeMode, null)];
        applyWpProc.running = true;
    }

    function refreshThemes(): void {
        applyThemesProc.command = ["bash", "-c",
            "matugen json " + Sh.q(schemePath) + " -c " + Sh.q(matugenConfig)];
        applyThemesProc.running = true;
    }

    function applyThemeSource(name: string, source: string, mode: string): void {
        if (!source) {
            console.warn("Wallpaper.applyThemeSource called with empty source")
            return
        }

        if (applyWpProc.running) {
            return
        }

        root.applyingWallpaper = root.committedWallpaper || "";

        applyWpProc.command = ["bash", "-c",
            "tmpimg=$(mktemp /tmp/pill-theme-XXXXXX.png)\n" +
            "magick -size 1x1 xc:" + Sh.q(source) + " \"$tmpimg\"\n" +
            root._matugenScript('"$tmpimg"', mode, null) +
            "rm -f \"$tmpimg\"\n"];
        applyWpProc.running = true;
    }
}
