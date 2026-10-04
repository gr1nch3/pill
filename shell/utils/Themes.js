.pragma library
// Static theme data and helpers. No QML dependencies: both the palette facade
// (components/Theme.qml) and the pipeline (services/ThemeController.qml) read
// this file, which is what breaks the old Theme <-> Wallpaper cycle.

var availableVariants = [
    { name: "scheme-content", label: "Content" },
    { name: "scheme-expressive", label: "Expressive" },
    { name: "scheme-fidelity", label: "Fidelity" },
    { name: "scheme-fruit-salad", label: "Fruit" },
    { name: "scheme-monochrome", label: "Mono" },
    { name: "scheme-neutral", label: "Neutral" },
    { name: "scheme-rainbow", label: "Rainbow" },
    { name: "scheme-tonal-spot", label: "Tonal" },
    { name: "scheme-vibrant", label: "Vibrant" }
]

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

// Fallback palette for the dynamic theme before matugen/ThemeEngine loads.
function dynamicFallback(mode) {
    var light = mode === "light"
    return {
        background:   light ? "#f0f0f0" : "#0b0b10",
        surface:      light ? "#e0e0e0" : "#15151a",
        surfaceHover: light ? "#d0d0d0" : "#1f1f28",
        highlight:    light ? "#c0c0c0" : "#2a2a35",
        accent:       "#4ecdc4",
        accentAlt:    "#7fdbda",
        text:         light ? "#1a1a1a" : "#f0f0f5",
        subtext:      "#8a8a99",
        danger:       "#ff6b6b",
        dangerBg:     "#2a1515",
        dangerHover:  "#3d1e1e",
        border:       "#28a8a899"
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
