pragma Singleton
// Fastfetch theming: Pill writes ~/.config/fastfetch/config.jsonc from the
// resolved palette on every theme change, so a bare `fastfetch` matches the
// shell (fixed themes included — no external scheme detour).
//
// The file is generated wholesale because JSONC can't be merged; a pre-existing
// config is backed up once to ~/.local/state/pill/backup/.
import QtQuick
import Quickshell

import "../utils"
import "../utils/shquote.js" as Sh
import "../utils/Themes.js" as Themes

Item {
    id: root

    property bool syncing: false
    property bool lastOk: false
    property bool everSynced: false
    property string lastError: ""

    readonly property string _configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string _stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/pill"

    readonly property string configPath: _configHome + "/fastfetch/config.jsonc"
    readonly property string backupPath: _stateDir + "/backup/fastfetch-config.jsonc"

    // ── Generated config ───────────────────────────────────────────────────
    // Colours use fastfetch's hex format; logo + module list are user choices
    // (Settings → Fastfetch) with a sensible default set.
    readonly property var defaultModules: ["title", "separator", "os", "host", "kernel", "uptime", "packages", "shell", "display", "de", "wm", "terminal", "cpu", "gpu", "memory", "disk", "localip", "battery", "break", "colors"]

    // Picker catalog: one row per module the settings dialog offers, in default
    // output order. `label` is the key fastfetch prints (empty = no key);
    // `verbose` is the friendlier long name behind Config.fastfetchVerboseKeys.
    readonly property var moduleCatalog: [
        {
            name: "title",
            label: "",
            verbose: "",
            desc: "User and hostname"
        },
        {
            name: "separator",
            label: "",
            verbose: "",
            desc: "A dividing line"
        },
        {
            name: "os",
            label: "OS",
            verbose: "OS",
            desc: "Distribution and version"
        },
        {
            name: "host",
            label: "Host",
            verbose: "Host",
            desc: "Machine model"
        },
        {
            name: "kernel",
            label: "Kernel",
            verbose: "Kernel",
            desc: "Kernel version"
        },
        {
            name: "uptime",
            label: "Uptime",
            verbose: "Uptime",
            desc: "Time since boot"
        },
        {
            name: "packages",
            label: "Packages",
            verbose: "Packages",
            desc: "Installed package count"
        },
        {
            name: "shell",
            label: "Shell",
            verbose: "Shell",
            desc: "Shell name and version"
        },
        {
            name: "display",
            label: "Display",
            verbose: "Display",
            desc: "Resolutions and refresh rates"
        },
        {
            name: "de",
            label: "DE",
            verbose: "Desktop",
            desc: "Desktop environment"
        },
        {
            name: "wm",
            label: "WM",
            verbose: "Window Manager",
            desc: "Window manager and version"
        },
        {
            name: "wmtheme",
            label: "WM Theme",
            verbose: "Window Theme",
            desc: "Window theme"
        },
        {
            name: "theme",
            label: "Theme",
            verbose: "Theme",
            desc: "Desktop theme"
        },
        {
            name: "icons",
            label: "Icons",
            verbose: "Icons",
            desc: "Icon theme"
        },
        {
            name: "font",
            label: "Font",
            verbose: "Font",
            desc: "System fonts"
        },
        {
            name: "cursor",
            label: "Cursor",
            verbose: "Cursor",
            desc: "Cursor theme"
        },
        {
            name: "terminal",
            label: "Terminal",
            verbose: "Terminal",
            desc: "Terminal name and version"
        },
        {
            name: "terminalfont",
            label: "Terminal Font",
            verbose: "Terminal Font",
            desc: "Font used by this terminal"
        },
        {
            name: "cpu",
            label: "CPU",
            verbose: "Processor",
            desc: "CPU model and clocks"
        },
        {
            name: "gpu",
            label: "GPU",
            verbose: "Graphics",
            desc: "GPU model(s)"
        },
        {
            name: "memory",
            label: "Memory",
            verbose: "Memory",
            desc: "RAM usage"
        },
        {
            name: "swap",
            label: "Swap",
            verbose: "Swap",
            desc: "Swap usage"
        },
        {
            name: "disk",
            label: "Disk",
            verbose: "Disks",
            desc: "Disk usage"
        },
        {
            name: "localip",
            label: "Local IP",
            verbose: "Local IP",
            desc: "Local addresses"
        },
        {
            name: "battery",
            label: "Battery",
            verbose: "Battery",
            desc: "Charge and status"
        },
        {
            name: "poweradapter",
            label: "Power Adapter",
            verbose: "Power Adapter",
            desc: "Charger and wattage"
        },
        {
            name: "locale",
            label: "Locale",
            verbose: "Locale",
            desc: "System locale"
        },
        {
            name: "datetime",
            label: "Date & Time",
            verbose: "Date & Time",
            desc: "Current date and time"
        },
        {
            name: "users",
            label: "Users",
            verbose: "Users",
            desc: "Logged-in users"
        },
        {
            name: "processes",
            label: "Processes",
            verbose: "Processes",
            desc: "Process and thread count"
        },
        {
            name: "loadavg",
            label: "Loadavg",
            verbose: "Load Average",
            desc: "System load averages"
        },
        {
            name: "bios",
            label: "BIOS",
            verbose: "BIOS",
            desc: "BIOS version and date"
        },
        {
            name: "board",
            label: "Board",
            verbose: "Motherboard",
            desc: "Motherboard model"
        },
        {
            name: "chassis",
            label: "Chassis",
            verbose: "Chassis",
            desc: "Machine type"
        },
        {
            name: "bluetooth",
            label: "Bluetooth",
            verbose: "Bluetooth",
            desc: "Connected Bluetooth devices"
        },
        {
            name: "wifi",
            label: "Wi-Fi",
            verbose: "Wi-Fi",
            desc: "Connected network"
        },
        {
            name: "netio",
            label: "Network IO",
            verbose: "Network I/O",
            desc: "Network throughput"
        },
        {
            name: "diskio",
            label: "Disk IO",
            verbose: "Disk I/O",
            desc: "Disk throughput"
        },
        {
            name: "publicip",
            label: "Public IP",
            verbose: "Public IP",
            desc: "Public address"
        },
        {
            name: "weather",
            label: "Weather",
            verbose: "Weather",
            desc: "Local weather"
        },
        {
            name: "init",
            label: "Init",
            verbose: "Init System",
            desc: "Init system (PID 1)"
        },
        {
            name: "lm",
            label: "LM",
            verbose: "Login Manager",
            desc: "Display/login manager"
        },
        {
            name: "version",
            label: "Version",
            verbose: "Version",
            desc: "fastfetch version"
        },
        {
            name: "break",
            label: "",
            verbose: "",
            desc: "A blank line"
        },
        {
            name: "colors",
            label: "",
            verbose: "",
            desc: "The terminal palette"
        }
    ]

    readonly property var moduleByName: {
        var m = {};
        for (var i = 0; i < root.moduleCatalog.length; i++)
            m[root.moduleCatalog[i].name] = root.moduleCatalog[i];
        return m;
    }

    function moduleMeta(name) {
        return root.moduleByName[name] || null;
    }

    function logoColor() {
        return {
            "1": Themes.hex(ThemeController.accent),
            "2": Themes.hex(ThemeController.accentAlt),
            "3": Themes.hex(ThemeController.text),
            "4": Themes.hex(ThemeController.subtext),
            "5": Themes.hex(ThemeController.accent),
            "6": Themes.hex(ThemeController.accentAlt)
        };
    }

    // The Pill mark: three bubbles growing along a diagonal, drawn with box
    // characters so any monospace font renders it. Fastfetch's `data` logo
    // wants one newline-joined string; $1..$3 take accent / accentAlt / text
    // from logoColor().
    readonly property string pillLogo: "    $3╭─╮\n" + "    $3│·│\n" + "    $3╰─╯\n" + "  $2╭───╮\n" + "  $2│ · │\n" + "  $2╰───╯\n" + "$1╭─────╮\n" + "$1│  ·  │\n" + "$1╰─────╯"

    function logoConfig() {
        var v = String(Config.fastfetchLogo || "auto").trim();
        if (v === "none")
            return null;
        var padding = {
            "top": 1,
            "left": 2
        };
        if (v === "" || v === "auto")
            return {
                "type": "auto",
                "padding": padding,
                "color": logoColor()
            };
        // "bubbles" is the pre-rename value for the same mark.
        if (v === "pill" || v === "bubbles")
            return {
                "type": "data",
                "source": pillLogo,
                "padding": padding,
                "color": logoColor()
            };
        if (v.indexOf("small:") === 0)
            return {
                "type": "small",
                "source": v.slice(6),
                "padding": padding,
                "color": logoColor()
            };
        if (v.indexOf("/") !== -1)
            return {
                "type": "file",
                "source": v,
                "padding": padding,
                "color": logoColor()
            };
        return {
            "type": "builtin",
            "source": v,
            "padding": padding,
            "color": logoColor()
        };
    }

    function moduleList() {
        var raw = String(Config.fastfetchModules || "");
        if (raw.trim() === "")
            return defaultModules;
        var parts = raw.split(/[,\n]/);
        var out = [];
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim();
            if (p !== "")
                out.push(p);
        }
        return out.length > 0 ? out : defaultModules;
    }

    // Module entries for the generated config: known modules carry an explicit
    // key so the printed label (and the key-column width) is deterministic;
    // unknown names stay plain strings and use fastfetch's own default key.
    function modulesForConfig() {
        var names = moduleList();
        var verbose = Config.fastfetchVerboseKeys;
        var out = [];
        for (var i = 0; i < names.length; i++) {
            var meta = root.moduleMeta(names[i]);
            if (!meta || meta.label === "") {
                out.push(names[i]);
                continue;
            }
            out.push({
                type: names[i],
                key: verbose ? (meta.verbose || meta.label) : meta.label
            });
        }
        return out;
    }

    // Key column: fastfetch moves the cursor to `key.width` after the key and
    // separator, so a longer key than the width would overlap its value. Fit
    // the longest printed key; min 12 keeps the classic look for short sets.
    // "both" prints an icon + space before the key, so it needs 2 more columns.
    function keyWidth(mods, keyType) {
        var max = 0;
        for (var i = 0; i < mods.length; i++) {
            var k = mods[i] && mods[i].key ? String(mods[i].key).length : 0;
            if (k > max)
                max = k;
        }
        var icon = keyType === "both" ? 2 : 0;
        return Math.max(12, max + icon + 3);
    }

    // Only fastfetch's own enum reaches the config file.
    readonly property var keyTypes: ["string", "both", "icon", "none"]

    function config() {
        var accent = Themes.hex(ThemeController.accent);
        var text = Themes.hex(ThemeController.text);
        var mods = modulesForConfig();
        var keyType = String(Config.fastfetchKeyType || "");
        if (keyTypes.indexOf(keyType) === -1)
            keyType = "string";

        var c = {
            "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
            "logo": logoConfig(),
            "display": {
                "separator": "  ",
                "color": {
                    "keys": accent,
                    "title": accent,
                    "output": text
                },
                "key": {
                    "width": keyWidth(mods, keyType),
                    "type": keyType
                }
            },
            "modules": mods
        };
        return "// Generated by Pill — rewritten on every theme change. Edits are lost.\n" + "// Customize the logo/modules in Settings → Fastfetch.\n" + "// Pre-existing config backed up to: " + backupPath + "\n" + JSON.stringify(c, null, 4) + "\n";
    }

    function script() {
        var dir = configPath.replace(/\/[^\/]*$/, "");
        var backupDir = backupPath.replace(/\/[^\/]*$/, "");
        var s = "set -e\n";
        s += "mkdir -p " + Sh.q(dir) + " " + Sh.q(backupDir) + "\n";
        s += "if [ -s " + Sh.q(configPath) + " ] && ! grep -q 'Generated by Pill' " + Sh.q(configPath) + " && [ ! -f " + Sh.q(backupPath) + " ]; then cp " + Sh.q(configPath) + " " + Sh.q(backupPath) + "; fi\n";
        s += "cat > " + Sh.q(configPath) + " << 'PILLEOF'\n" + config() + "\nPILLEOF\n";
        s += "echo PILL_FASTFETCH_OK\n";
        return s;
    }

    function sync(force) {
        if (!Config.fastfetchEnabled && force !== true)
            return;
        if (!Integrations.ready) {
            if (_pending)
                return;
            _pending = true;
            Integrations.whenReady(function () {
                root._pending = false;
                root.sync(force);
            });
            return;
        }
        if (!Integrations.has("fastfetch"))
            return;
        syncing = true;
        syncCmd.command = ["bash", "-c", script()];
        syncCmd.run();
    }

    property bool _pending: false

    Timer {
        id: debounce
        interval: 400
        onTriggered: root.sync()
    }

    function schedule() {
        debounce.restart();
    }

    Cmd {
        id: syncCmd
        autorun: false
        property string tail: ""
        onLine: function (line) {
            if (line.trim() !== "")
                syncCmd.tail = line.trim();
        }
        onDone: function (code) {
            root.syncing = false;
            root.everSynced = true;
            root.lastOk = code === 0 && syncCmd.tail === "PILL_FASTFETCH_OK";
            root.lastError = root.lastOk ? "" : (syncCmd.tail || ("exit " + code));
            syncCmd.tail = "";
        }
    }
}
