.pragma library
// Static theme data and helpers. No QML dependencies: both the palette facade
// (components/Theme.qml) and the pipeline (services/ThemeController.qml) read
// this file, which is what breaks the old Theme <-> Wallpaper cycle.

// ── Shape + motion tokens ───────────────────────────────────────────────────
// Themes carry more than colour: corner scale, border weights and motion
// speed. Builtins use these defaults; a theme may override any subset.
var defaultShape = {
    style: "rounded",     // rounded | rect | parallelogram | trapezoid | hex
    slant: 0.35,          // polygon cut ratio (of height)
    radius: {
        hairline: 3,      // track fills, indicator bars
        small: 6,         // stepper buttons, tiny controls
        control: 8,       // chips, buttons, icon tiles
        row: 10,          // setting rows, list rows
        card: 12,         // cards, knobs
        cardLarge: 14,    // large cards, slider bars
        tile: 16,         // big tiles (ToggleTile, IconButton)
        notification: 20, // expanded notification pill
        panel: 24         // island panels
    },
    border: { width: 1, emphasis: 2 }
}

var defaultMotion = {
    fast: 80,    // hover tints, small state flips
    hover: 100,  // hover transitions
    normal: 150, // control movement
    panel: 200,  // content fades, panel resizes
    pill: 320    // island size/position
}

function _num(v, fallback) {
    return (typeof v === "number" && isFinite(v)) ? v : fallback
}

function mergeShape(s) {
    var d = defaultShape
    if (!s || typeof s !== "object") return d
    var r = s.radius || {}
    var b = s.border || {}
    return {
        style: (typeof s.style === "string" && s.style !== "") ? s.style : d.style,
        slant: _num(s.slant, d.slant),
        radius: {
            hairline: _num(r.hairline, d.radius.hairline),
            small: _num(r.small, d.radius.small),
            control: _num(r.control, d.radius.control),
            row: _num(r.row, d.radius.row),
            card: _num(r.card, d.radius.card),
            cardLarge: _num(r.cardLarge, d.radius.cardLarge),
            tile: _num(r.tile, d.radius.tile),
            notification: _num(r.notification, d.radius.notification),
            panel: _num(r.panel, d.radius.panel)
        },
        border: {
            width: _num(b.width, d.border.width),
            emphasis: _num(b.emphasis, d.border.emphasis)
        }
    }
}

function mergeMotion(m) {
    var d = defaultMotion
    if (!m || typeof m !== "object") return d
    return {
        fast: _num(m.fast, d.fast),
        hover: _num(m.hover, d.hover),
        normal: _num(m.normal, d.normal),
        panel: _num(m.panel, d.panel),
        pill: _num(m.pill, d.pill)
    }
}

// Horizontal inset a polygon style eats at a given size (0 for rounded/rect).
// Clamped so large panels don't get absurd cuts and tiny chips stay sane.
function shapeCut(style, slant, w, h) {
    if (style !== "parallelogram" && style !== "trapezoid" && style !== "hex") return 0
    return Math.min(h * slant, 40, w * 0.2)
}

// Copy a theme with its shape/motion merged over the defaults.
function withStyle(t) {
    var out = {}
    for (var k in t) out[k] = t[k]
    out.shape = mergeShape(t.shape)
    out.motion = mergeMotion(t.motion)
    return out
}

var themeKeys = ["background", "surface", "surfaceHover", "highlight", "accent",
    "accentAlt", "text", "subtext", "danger", "dangerBg", "dangerHover", "border"]

// Fallback palette for the dynamic theme before wallust/ThemeEngine loads.
function dynamicFallback() {
    return {
        background:   "#0b0b10",
        surface:      "#15151a",
        surfaceHover: "#1f1f28",
        highlight:    "#2a2a35",
        accent:       "#4ecdc4",
        accentAlt:    "#7fdbda",
        text:         "#f0f0f5",
        subtext:      "#8a8a99",
        danger:       "#ff6b6b",
        dangerBg:     "#2a1515",
        dangerHover:  "#3d1e1e",
        border:       "#28a8a899"
    }
}

// ── wallust colourscheme → Bubbles roles ────────────────────────────────────
// wallust emits an ANSI scheme (color0..15 plus background/foreground/cursor).
// Slot order depends on its palette mode (`ansi` is tty-ordered, `kmeans` and
// `salience` are generated) and two-tone art can yield a muted ramp, so
// Bubbles picks errors/accents by hue and saturation instead of trusting
// indices, pushes them into a readable band, and builds the surface ladder
// from the background's own hue (no colour drift toward the foreground).
function _bytes(h) {
    var s = String(h).replace("#", "")
    return [parseInt(s.substr(0, 2), 16), parseInt(s.substr(2, 2), 16), parseInt(s.substr(4, 2), 16)]
}

function _hx(v) {
    var s = Math.max(0, Math.min(255, Math.round(v))).toString(16)
    return s.length < 2 ? "0" + s : s
}

function _mix(a, b, t) {
    var pa = _bytes(a), pb = _bytes(b)
    return "#" + _hx(pa[0] + (pb[0] - pa[0]) * t) +
        _hx(pa[1] + (pb[1] - pa[1]) * t) + _hx(pa[2] + (pb[2] - pa[2]) * t)
}

function _hsl(c) {
    var r = c[0] / 255, g = c[1] / 255, b = c[2] / 255
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, s = 0, h = 0
    if (mx !== mn) {
        var d = mx - mn
        s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
        if (mx === r) h = (g - b) / d + (g < b ? 6 : 0)
        else if (mx === g) h = (b - r) / d + 2
        else h = (r - g) / d + 4
        h *= 60
    }
    return { h: h, s: s, l: l }
}

function _hslHex(h, s, l) {
    var f = function(n) {
        var k = (n + h / 30) % 12
        var a = s * Math.min(l, 1 - l)
        return 255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)))
    }
    return "#" + _hx(f(0)) + _hx(f(8)) + _hx(f(4))
}

// Lighten (or darken, on a light background) while keeping the colour's own
// hue/saturation, so layers stay in the wallpaper's family.
function _shift(hex, amount) {
    var c = _hsl(_bytes(hex))
    var l = c.l + (c.l > 0.5 ? -amount : amount)
    return _hslHex(c.h, c.s, Math.max(0, Math.min(1, l)))
}

// Lift a colour's lightness while keeping its hue/saturation; the bright ANSI
// half is a lifted version of its base slot.
function _lighten(hex, amount) {
    var c = _hsl(_bytes(hex))
    return _hslHex(c.h, c.s, Math.max(0, Math.min(1, c.l + amount)))
}

// Push a chromatic colour into a readable band. Grey stays grey (boosting a
// zero-saturation colour would invent a hue out of nothing).
function _boost(hex) {
    var c = _hsl(_bytes(hex))
    if (c.s < 0.15) return hex
    return _hslHex(c.h, Math.max(c.s, 0.55), Math.min(0.68, Math.max(0.50, c.l)))
}

// Text has to read on the panel, not just mirror wallust's foreground: dark
// palettes get their foreground lifted toward its own hue's light end (light
// palettes the reverse). Greys stay grey.
function _readable(hex, bg) {
    var c = _hsl(_bytes(hex))
    var dark = _hsl(_bytes(bg)).l < 0.5
    var l = dark ? Math.max(c.l, 0.78) : Math.min(c.l, 0.25)
    var s = c.s < 0.12 ? c.s : Math.max(c.s, 0.45)
    return _hslHex(c.h, s, l)
}

function _hueDist(a, b) {
    var d = Math.abs(a - b) % 360
    return d > 180 ? 360 - d : d
}

function _vivid(c) { return c.s * (1 - 0.4 * Math.abs(c.l - 0.55)) }

function paletteFromWallust(scheme) {
    var get = function(k) {
        var v = scheme ? scheme[k] : ""
        return (typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v)) ? v : ""
    }
    var bg = get("background") || get("color0")
    var fg = get("foreground") || get("color7")
    if (bg === "" || fg === "") return dynamicFallback()
    var cands = []
    for (var i = 1; i <= 6; i++) {
        var hex = get("color" + i)
        if (hex !== "") cands.push({ hex: hex.toLowerCase(), hsl: _hsl(_bytes(hex)) })
    }
    // Error colour: the candidate closest to red that has visible chroma. If
    // the palette has no red-ish hue (a blue forest, a grey photo), fall back
    // to a constant red instead of boosting an unrelated hue.
    var danger = ""
    var best = 60
    for (i = 0; i < cands.length; i++) {
        var d = Math.min(cands[i].hsl.h, 360 - cands[i].hsl.h)
        if (cands[i].hsl.s > 0.2 && cands[i].hsl.l > 0.15 && d < best) {
            best = d
            danger = cands[i].hex
        }
    }
    var err = danger === "" ? "#ff6b6b" : _boost(danger)
    // Accent: the most vivid remaining colour; alt: the next one whose hue is
    // far enough away to read as a second accent. Near-black candidates are
    // skipped — their hue is noise and their boosted version vanishes.
    var rest = []
    for (i = 0; i < cands.length; i++) {
        if (danger !== "" && cands[i].hex === danger) continue
        if (cands[i].hsl.l < 0.15 || (cands[i].hsl.s < 0.15 && cands[i].hsl.l < 0.28)) continue
        rest.push(cands[i])
    }
    rest.sort(function(a, b) { return _vivid(b.hsl) - _vivid(a.hsl) })
    var accent = rest.length > 0 ? rest[0].hex : (get("color6") || "#4ecdc4")
    var accentAlt = accent
    for (i = 1; i < rest.length; i++) {
        if (_hueDist(rest[i].hsl.h, rest[0].hsl.h) > 40) { accentAlt = rest[i].hex; break }
    }
    var text = _readable(fg, bg)
    return {
        background:   _shift(bg, 0.04),
        surface:      _shift(bg, 0.09),
        surfaceHover: _shift(bg, 0.15),
        highlight:    _shift(bg, 0.22),
        accent:       _boost(accent),
        accentAlt:    _boost(accentAlt),
        text:         text,
        subtext:      _mix(bg, text, 0.55),
        danger:       err,
        dangerBg:     _mix(bg, err, 0.18),
        dangerHover:  _mix(bg, err, 0.30),
        border:       _shift(bg, 0.28)
    }
}

// wallust's raw scheme -> the ANSI scheme the user's app templates get.
// kmeans clusters dark wallpapers near-black, so raw slots are what made
// terminals too dark: keep the wallpaper's own hues, but lift text, the
// background and every chromatic slot into a readable band, with the bright
// half a lifted version of the base half. null when unusable (no colours).
function _ansiSlot(hex, bg) {
    if (hex === "")
        return _readable("#888888", bg)
    var c = _hsl(_bytes(hex))
    if (c.s < 0.15)
        return _hslHex(c.h, c.s, Math.min(0.72, Math.max(0.5, c.l)))
    return _boost(hex)
}

function readableWallust(scheme) {
    var get = function(k) {
        var v = scheme ? scheme[k] : ""
        return (typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v)) ? v.toLowerCase() : ""
    }
    var bg = get("background") || get("color0")
    var fg = get("foreground") || get("color7")
    if (bg === "" || fg === "")
        return null
    var text = _readable(fg, bg)
    var out = {
        cursor: text,
        background: _shift(bg, 0.03),
        foreground: text,
        color0: _shift(bg, 0.03),
        color7: text,
        color8: _mix(bg, text, 0.45),
        color15: _lighten(text, 0.08)
    }
    for (var i = 1; i <= 6; i++) {
        var base = _ansiSlot(get("color" + i), bg)
        out["color" + i] = base
        out["color" + (i + 8)] = _lighten(base, 0.14)
    }
    return out
}

// Reverse map: a wallust colourscheme for `wallust cs` synthesized from the
// resolved Bubbles palette, so fixed themes retint apps in their own colours.
// Only used for template rendering — Bubbles never reads it back. The bright
// half is a lifted version of the base slot, never a background layer (dark
// bright-slots are unreadable for `ls --color`-style output).
function wallustFromPalette(p) {
    var accent = hex(p.accent)
    var accentAlt = hex(p.accentAlt)
    var danger = hex(p.danger)
    var text = hex(p.text)
    return {
        cursor: accent, background: hex(p.background),
        foreground: text, color0: hex(p.background), color1: danger,
        color2: accentAlt, color3: accent, color4: accentAlt,
        color5: accent, color6: accent, color7: text,
        color8: hex(p.subtext), color9: _lighten(danger, 0.12),
        color10: _lighten(accentAlt, 0.12), color11: _lighten(accent, 0.12),
        color12: _lighten(accentAlt, 0.16), color13: _lighten(accent, 0.16),
        color14: _lighten(accent, 0.16), color15: _lighten(text, 0.08)
    }
}

var builtins = [
    {
        name: "ariadne", label: "ariadne", source: "#4ecdc4", mode: "dark",
        background: "#0b0b10", surface: "#15151a", surfaceHover: "#1f1f28",
        highlight: "#2a2a35", accent: "#4ecdc4", accentAlt: "#7fdbda",
        text: "#f0f0f5", subtext: "#8a8a99", danger: "#ff6b6b",
        dangerBg: "#2a1515", dangerHover: "#3d1e1e", border: "#28a8a899"
    },
    {
        name: "gruvbox", label: "Gruvbox", source: "#d79921", mode: "dark",
        background: "#282828", surface: "#3c3836", surfaceHover: "#504945",
        highlight: "#665c54", accent: "#d79921", accentAlt: "#b57614",
        text: "#ebdbb2", subtext: "#a89984", danger: "#cc241d",
        dangerBg: "#3c1c1c", dangerHover: "#4e2020", border: "#44a89984"
    },
    {
        name: "catppuccin", label: "Catppuccin", source: "#cba6f7", mode: "dark",
        background: "#1e1e2e", surface: "#313244", surfaceHover: "#45475a",
        highlight: "#585b70", accent: "#cba6f7", accentAlt: "#89b4fa",
        text: "#cdd6f4", subtext: "#a6adc8", danger: "#f38ba8",
        dangerBg: "#2c1e2e", dangerHover: "#3d2040", border: "#44a6adc8"
    },
    {
        name: "tokyonight", label: "Tokyo Night", source: "#7aa2f7", mode: "dark",
        background: "#1a1b26", surface: "#24283b", surfaceHover: "#2e3248",
        highlight: "#3b4261", accent: "#7aa2f7", accentAlt: "#bb9af7",
        text: "#c0caf5", subtext: "#565f89", danger: "#f7768e",
        dangerBg: "#2a1520", dangerHover: "#3d1e2e", border: "#44565f89"
    },
    {
        name: "nord", label: "Nord", source: "#88c0d0", mode: "dark",
        background: "#2e3440", surface: "#3b4252", surfaceHover: "#434c5e",
        highlight: "#4c566a", accent: "#88c0d0", accentAlt: "#81a1c1",
        text: "#eceff4", subtext: "#d8dee9", danger: "#bf616a",
        dangerBg: "#2d1f22", dangerHover: "#3d2528", border: "#444c566a"
    },
    {
        name: "rosepine", label: "Rosé Pine", source: "#eb6f92", mode: "dark",
        background: "#191724", surface: "#1f1d2e", surfaceHover: "#26233a",
        highlight: "#403d52", accent: "#eb6f92", accentAlt: "#f6c177",
        text: "#e0def4", subtext: "#6e6a86", danger: "#eb6f92",
        dangerBg: "#2a1020", dangerHover: "#3d1530", border: "#446e6a86"
    },
    {
        name: "everforest", label: "Everforest", source: "#a7c080", mode: "dark",
        background: "#272e33", surface: "#2e383c", surfaceHover: "#374145",
        highlight: "#414b50", accent: "#a7c080", accentAlt: "#83c092",
        text: "#d3c6aa", subtext: "#859289", danger: "#e67e80",
        dangerBg: "#2c1e1e", dangerHover: "#3d2828", border: "#44859289"
    },
    {
        name: "dracula", label: "Dracula", source: "#bd93f9", mode: "dark",
        background: "#282a36", surface: "#323442", surfaceHover: "#3b3e4d",
        highlight: "#44475a", accent: "#bd93f9", accentAlt: "#ff79c6",
        text: "#f8f8f2", subtext: "#6272a4", danger: "#ff5555",
        dangerBg: "#4f323c", dangerHover: "#69373f", border: "#446272a4"
    },
    {
        name: "kanagawa", label: "Kanagawa", source: "#7e9cd8", mode: "dark",
        background: "#1f1f28", surface: "#2a2a37", surfaceHover: "#363646",
        highlight: "#54546d", accent: "#7e9cd8", accentAlt: "#957fb8",
        text: "#dcd7ba", subtext: "#727169", danger: "#e82424",
        dangerBg: "#432027", dangerHover: "#5b2127", border: "#44727169"
    },
    {
        name: "onedark", label: "One Dark", source: "#61afef", mode: "dark",
        background: "#282c34", surface: "#30353f", surfaceHover: "#3a404b",
        highlight: "#454c59", accent: "#61afef", accentAlt: "#c678dd",
        text: "#abb2bf", subtext: "#5c6370", danger: "#e06c75",
        dangerBg: "#493840", dangerHover: "#5f3f48", border: "#445c6370"
    },
    {
        name: "github", label: "GitHub", source: "#58a6ff", mode: "dark",
        background: "#0d1117", surface: "#161b22", surfaceHover: "#21262d",
        highlight: "#30363d", accent: "#58a6ff", accentAlt: "#bc8cff",
        text: "#e6edf3", subtext: "#8b949e", danger: "#f85149",
        dangerBg: "#371d20", dangerHover: "#542426", border: "#448b949e"
    },
    {
        name: "ayu", label: "Ayu", source: "#ffb454", mode: "dark",
        background: "#0a0e14", surface: "#131721", surfaceHover: "#1b2230",
        highlight: "#253040", accent: "#ffb454", accentAlt: "#59c2ff",
        text: "#bfbdb6", subtext: "#6c7680", danger: "#f07178",
        dangerBg: "#332026", dangerHover: "#4f2c32", border: "#446c7680"
    },
    {
        name: "monokai", label: "Monokai", source: "#a6e22e", mode: "dark",
        background: "#272822", surface: "#31322c", surfaceHover: "#3a3b34",
        highlight: "#49483e", accent: "#a6e22e", accentAlt: "#66d9ef",
        text: "#f8f8f2", subtext: "#75715e", danger: "#f92672",
        dangerBg: "#4d2830", dangerHover: "#66273a", border: "#4475715e"
    },
    {
        name: "latte", label: "Catppuccin Latte", source: "#8839ef", mode: "light",
        background: "#eff1f5", surface: "#e6e9ef", surfaceHover: "#dce0e8",
        highlight: "#ccd0da", accent: "#8839ef", accentAlt: "#1e66f5",
        text: "#4c4f69", subtext: "#6c6f85", danger: "#d20f39",
        dangerBg: "#f9dde3", dangerHover: "#f4c5cf", border: "#b0b4c0"
    },
    {
        name: "gruvbox-light", label: "Gruvbox Light", source: "#af3a03", mode: "light",
        background: "#fbf1c7", surface: "#f2e5bc", surfaceHover: "#ebdbb2",
        highlight: "#d5c4a1", accent: "#af3a03", accentAlt: "#458588",
        text: "#3c3836", subtext: "#7c6f64", danger: "#cc241d",
        dangerBg: "#f8e0df", dangerHover: "#f3cac9", border: "#b9a89984"
    },
    {
        name: "sharp", label: "Sharp", source: "#56b6c2", mode: "dark",
        background: "#0c0e12", surface: "#15181e", surfaceHover: "#1d2129",
        highlight: "#262b35", accent: "#56b6c2", accentAlt: "#e5c07b",
        text: "#d7dae0", subtext: "#8a919c", danger: "#e06c75",
        dangerBg: "#2b1b1e", dangerHover: "#3a2226", border: "#4d8a919c",
        shape: {
            style: "rect",
            radius: { hairline: 1, small: 2, control: 3, row: 4, card: 6,
                cardLarge: 6, tile: 8, notification: 10, panel: 12 },
            border: { width: 1, emphasis: 2 }
        },
        motion: { fast: 60, hover: 80, normal: 120, panel: 160, pill: 240 }
    },
    {
        name: "paper", label: "Paper", source: "#b45309", mode: "light",
        background: "#f6f3ee", surface: "#ece7df", surfaceHover: "#e0d9ce",
        highlight: "#d2c9bb", accent: "#b45309", accentAlt: "#0f766e",
        text: "#1f1b16", subtext: "#6b6257", danger: "#b91c1c",
        dangerBg: "#f6dede", dangerHover: "#ecc7c7", border: "#b9b0a2",
        shape: {
            radius: { hairline: 4, small: 10, control: 14, row: 18, card: 20,
                cardLarge: 22, tile: 24, notification: 28, panel: 32 },
            border: { width: 1, emphasis: 2 }
        },
        motion: { fast: 120, hover: 160, normal: 220, panel: 280, pill: 420 }
    },
    {
        name: "oblique", label: "Oblique", source: "#b388ff", mode: "dark",
        background: "#0f0a1a", surface: "#1a1230", surfaceHover: "#241a40",
        highlight: "#2f2352", accent: "#b388ff", accentAlt: "#00e5ff",
        text: "#e8e0ff", subtext: "#9a8fc0", danger: "#ff5370",
        dangerBg: "#2a1020", dangerHover: "#3d1830", border: "#4d9a8fc0",
        shape: {
            style: "parallelogram",
            slant: 0.4,
            radius: { panel: 8, card: 6, control: 4 }
        },
        motion: { fast: 70, hover: 90, normal: 130, panel: 170, pill: 260 }
    }
]

// Strict validation so one bad user file cannot blank the picker.
function validUserTheme(t) {
    if (!t || typeof t !== "object") return null
    if (!t.name || t.name === "dynamic") return null
    if (typeof t.source !== "string" || t.source === "") return null
    for (var i = 0; i < themeKeys.length; i++)
        if (typeof t[themeKeys[i]] !== "string") return null
    var out = { name: t.name, label: t.label || t.name, source: t.source, mode: t.mode || "dark" }
    for (var j = 0; j < themeKeys.length; j++) out[themeKeys[j]] = t[themeKeys[j]]
    out.shape = t.shape
    out.motion = t.motion
    return withStyle(out)
}

function hex(c) {
    var s = "" + c
    return s.length === 9 ? "#" + s.slice(3) : s   // strip #AARRGGBB alpha
}

function contrast(c) {
    return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.55 ? "#1a1a1a" : "#f5f5f5"
}
