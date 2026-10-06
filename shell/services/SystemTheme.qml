pragma Singleton
// System theme sync: Pill writes the resolved palette to the places GTK and
// Qt actually read, so fixed themes retint the desktop too (not only the
// dynamic route). Owned files:
//   ~/.config/gtk-3.0/gtk.css      (managed marker block, user content kept,
//   ~/.config/gtk-4.0/gtk.css       one-time .pill-bak before first write)
//   ~/.config/qt6ct/colors/pill.conf   (already the user's qt6ct target)
// plus `gsettings color-scheme` for libadwaita/portal consumers.
// GTK apps pick changes up on next launch; nothing here edits user configs
// beyond the managed block.
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
    readonly property string _legacyStateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/bubbles"

    readonly property string gtk3Path: _configHome + "/gtk-3.0/gtk.css"
    readonly property string gtk4Path: _configHome + "/gtk-4.0/gtk.css"
    readonly property string qtPath: _configHome + "/qt6ct/colors/pill.conf"

    // ── Palette helpers ────────────────────────────────────────────────────

    function luma(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    }

    function onColor(c) {
        return luma(c) > 0.55 ? "#1a1a1a" : "#f5f5f5";
    }

    readonly property bool dark: luma(ThemeController.background) < 0.5

    // ── GTK ────────────────────────────────────────────────────────────────
    function gtkBlock() {
        var bg = Themes.hex(ThemeController.background), surf = Themes.hex(ThemeController.surface), fg = Themes.hex(ThemeController.text);
        var dim = Themes.hex(ThemeController.subtext), accent = Themes.hex(ThemeController.accent), accentAlt = Themes.hex(ThemeController.accentAlt);
        var danger = Themes.hex(ThemeController.danger), dangerBg = Themes.hex(ThemeController.dangerBg), border = Themes.hex(ThemeController.border);
        var accentFg = onColor(ThemeController.accent);
        var l = [];
        l.push("/* pill:generated:start — rewritten on every theme change; edits are lost */");
        l.push("/* GTK4 / libadwaita */");
        l.push("@define-color accent_color " + accent + ";");
        l.push("@define-color accent_bg_color " + accent + ";");
        l.push("@define-color accent_fg_color " + accentFg + ";");
        l.push("@define-color window_bg_color " + bg + ";");
        l.push("@define-color window_fg_color " + fg + ";");
        l.push("@define-color headerbar_bg_color " + surf + ";");
        l.push("@define-color headerbar_fg_color " + fg + ";");
        l.push("@define-color headerbar_backdrop_color " + surf + ";");
        l.push("@define-color popover_bg_color " + surf + ";");
        l.push("@define-color popover_fg_color " + fg + ";");
        l.push("@define-color view_bg_color " + bg + ";");
        l.push("@define-color view_fg_color " + fg + ";");
        l.push("@define-color card_bg_color " + surf + ";");
        l.push("@define-color card_fg_color " + fg + ";");
        l.push("@define-color dialog_bg_color " + surf + ";");
        l.push("@define-color dialog_fg_color " + fg + ";");
        l.push("@define-color sidebar_bg_color @window_bg_color;");
        l.push("@define-color sidebar_fg_color @window_fg_color;");
        l.push("@define-color sidebar_backdrop_color @window_bg_color;");
        l.push("@define-color sidebar_border_color @window_bg_color;");
        l.push("@define-color destructive_bg_color " + danger + ";");
        l.push("@define-color destructive_fg_color " + accentFg + ";");
        l.push("@define-color destructive_color " + danger + ";");
        l.push("@define-color error_bg_color " + dangerBg + ";");
        l.push("@define-color error_fg_color " + danger + ";");
        l.push("@define-color error_color " + danger + ";");
        l.push("@define-color warning_bg_color #f0a500;");
        l.push("@define-color warning_fg_color #241a00;");
        l.push("@define-color warning_color #f0a500;");
        l.push("@define-color success_bg_color " + accentAlt + ";");
        l.push("@define-color success_fg_color " + accentFg + ";");
        l.push("@define-color success_color " + accentAlt + ";");
        l.push("/* GTK3 */");
        l.push("@define-color theme_bg_color " + bg + ";");
        l.push("@define-color theme_fg_color " + fg + ";");
        l.push("@define-color theme_base_color " + bg + ";");
        l.push("@define-color theme_text_color " + fg + ";");
        l.push("@define-color theme_selected_bg_color " + accent + ";");
        l.push("@define-color theme_selected_fg_color " + accentFg + ";");
        l.push("@define-color theme_unfocused_bg_color " + bg + ";");
        l.push("@define-color theme_unfocused_fg_color " + dim + ";");
        l.push("@define-color theme_unfocused_base_color " + bg + ";");
        l.push("@define-color theme_unfocused_text_color " + dim + ";");
        l.push("@define-color theme_unfocused_selected_bg_color " + accent + ";");
        l.push("@define-color theme_unfocused_selected_fg_color " + accentFg + ";");
        l.push("@define-color insensitive_bg_color " + surf + ";");
        l.push("@define-color insensitive_fg_color " + dim + ";");
        l.push("@define-color insensitive_base_color " + bg + ";");
        l.push("@define-color unfocused_insensitive_color " + dim + ";");
        l.push("@define-color borders " + border + ";");
        l.push("@define-color unfocused_borders " + border + ";");
        l.push("@define-color content_view_bg " + bg + ";");
        l.push("/* pill:generated:end */");
        return l.join("\n");
    }

    // ── Qt6ct color scheme (KDE INI format) ────────────────────────────────
    function _qtSection(name, extraHeader) {
        var bg = Themes.hex(ThemeController.background), alt = Themes.hex(ThemeController.surface), fg = Themes.hex(ThemeController.text);
        var dim = Themes.hex(ThemeController.subtext), accent = Themes.hex(ThemeController.accent), link = Themes.hex(ThemeController.accentAlt);
        var neg = Themes.hex(ThemeController.danger), neutral = Themes.hex(ThemeController.accentAlt);
        var head = extraHeader ? "[" + name + "][" + extraHeader + "]" : "[" + name + "]";
        var l = [];
        l.push(head);
        l.push("BackgroundAlternate=" + alt);
        l.push("BackgroundNormal=" + bg);
        l.push("DecorationFocus=" + accent);
        l.push("DecorationHover=" + accent);
        l.push("ForegroundActive=" + accent);
        l.push("ForegroundInactive=" + dim);
        l.push("ForegroundLink=" + link);
        l.push("ForegroundNegative=" + neg);
        l.push("ForegroundNeutral=" + neutral);
        l.push("ForegroundNormal=" + fg);
        l.push("ForegroundPositive=" + accent);
        l.push("ForegroundVisited=" + link);
        return l.join("\n");
    }

    function qtConf() {
        var accent = Themes.hex(ThemeController.accent), accentFg = onColor(ThemeController.accent);
        var bg = Themes.hex(ThemeController.background), alt = Themes.hex(ThemeController.surface);
        var danger = Themes.hex(ThemeController.danger), dangerBg = Themes.hex(ThemeController.dangerBg);
        var dim = Themes.hex(ThemeController.subtext), link = Themes.hex(ThemeController.accentAlt);
        var l = [];
        l.push("# Generated by Pill — rewritten on every theme change.");
        l.push("");
        l.push("[ColorEffects:Disabled]");
        l.push("Color=" + alt);
        l.push("ColorAmount=0.5");
        l.push("ColorEffect=3");
        l.push("ContrastAmount=0");
        l.push("ContrastEffect=0");
        l.push("IntensityAmount=0");
        l.push("IntensityEffect=0");
        l.push("");
        l.push("[ColorEffects:Inactive]");
        l.push("ChangeSelectionColor=true");
        l.push("Color=" + bg);
        l.push("ColorAmount=0.025");
        l.push("ColorEffect=0");
        l.push("ContrastAmount=0.1");
        l.push("ContrastEffect=0");
        l.push("Enable=true");
        l.push("IntensityAmount=0");
        l.push("IntensityEffect=0");
        l.push("");
        l.push(_qtSection("Colors:Button"));
        l.push("");
        l.push(_qtSection("Colors:Complementary"));
        l.push("");
        l.push(_qtSection("Colors:Header"));
        l.push("");
        l.push(_qtSection("Colors:Header", "Inactive"));
        l.push("");
        l.push("[Colors:Selection]");
        l.push("BackgroundAlternate=" + accent);
        l.push("BackgroundNormal=" + accent);
        l.push("DecorationFocus=" + accent);
        l.push("DecorationHover=" + accent);
        l.push("ForegroundActive=" + accentFg);
        l.push("ForegroundInactive=" + accentFg);
        l.push("ForegroundLink=" + link);
        l.push("ForegroundNegative=" + danger);
        l.push("ForegroundNeutral=" + accentFg);
        l.push("ForegroundNormal=" + accentFg);
        l.push("ForegroundPositive=" + accent);
        l.push("ForegroundVisited=" + link);
        l.push("");
        l.push(_qtSection("Colors:Tooltip"));
        l.push("");
        l.push(_qtSection("Colors:View"));
        l.push("");
        l.push(_qtSection("Colors:Window"));
        l.push("");
        l.push("[Colors:Window][Inactive]");
        l.push("BackgroundNormal=" + bg);
        l.push("ForegroundNormal=" + dim);
        l.push("ForegroundInactive=" + dim);
        l.push("");
        l.push("[General]");
        l.push("ColorScheme=Pill");
        l.push("Name=Pill");
        l.push("shadeSortColumn=true");
        return l.join("\n");
    }

    // ── Sync ───────────────────────────────────────────────────────────────
    function script() {
        var gtk = gtkBlock();
        var qt = qtConf();
        var backupDir = _stateDir + "/backup";
        var s = "set -e\n";
        s += "if [ ! -d " + Sh.q(backupDir) + " ] && [ -d " + Sh.q(_legacyStateDir + "/backup") + " ]; then " + "mv " + Sh.q(_legacyStateDir + "/backup") + " " + Sh.q(backupDir) + "; fi\n";
        s += "mkdir -p " + Sh.q(_configHome + "/gtk-3.0") + " " + Sh.q(_configHome + "/gtk-4.0") + " " + Sh.q(_configHome + "/qt6ct/colors") + " " + Sh.q(backupDir) + "\n";
        s += "for f in " + Sh.q(gtk3Path) + " " + Sh.q(gtk4Path) + "; do\n";
        s += "  [ -f \"$f\" ] || : > \"$f\"\n";
        s += "  bk=" + Sh.q(backupDir) + "/$(basename \"$(dirname \"$f\")\")-$(basename \"$f\")\n";
        s += "  if [ -s \"$f\" ] && ! grep -q 'pill:generated:start' \"$f\" && [ ! -f \"$bk\" ]; then\n";
        s += "    cp \"$f\" \"$bk\"\n";
        s += "  fi\n";
        s += "  sed -i '/pill:generated:start/,/pill:generated:end/d' \"$f\"\n";
        s += "  cat >> \"$f\" << 'PILLEOF'\n" + gtk + "\nPILLEOF\n";
        s += "done\n";
        s += "cat > " + Sh.q(qtPath) + " << 'PILLEOF'\n" + qt + "\nPILLEOF\n";
        if (Integrations.has("gsettings"))
            s += "gsettings set org.gnome.desktop.interface color-scheme " + (dark ? "prefer-dark" : "prefer-light") + "\n";
        s += "echo PILL_THEME_OK\n";
        return s;
    }

    function sync(force) {
        if (!Config.syncSystemTheme && force !== true)
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
        syncing = true;
        syncCmd.command = ["bash", "-c", script()];
        syncCmd.run();
    }

    property bool _pending: false

    // Dynamic palettes land asynchronously; resync when ThemeEngine loads.
    Connections {
        target: ThemeEngine
        function onLoadedChanged() {
            root.schedule();
        }
    }

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
            root.lastOk = code === 0 && syncCmd.tail === "PILL_THEME_OK";
            root.lastError = root.lastOk ? "" : (syncCmd.tail || ("exit " + code));
            syncCmd.tail = "";
        }
    }
}
