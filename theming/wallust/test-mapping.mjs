// Run: node theming/wallust/test-mapping.mjs
// Checks the wallust -> Pill role mapping in shell/utils/Themes.js against
// real `wallust run --palette kmeans` colourschemes.
import { readFileSync } from "node:fs"
import assert from "node:assert/strict"

const src = readFileSync(new URL("../../shell/utils/Themes.js", import.meta.url), "utf8")
const { paletteFromWallust, wallustFromPalette, readableWallust, dynamicFallback,
    builtins, validUserTheme, statusColors } =
    new Function(src.replace(".pragma library", "") +
        "\nreturn { paletteFromWallust, wallustFromPalette, readableWallust, dynamicFallback, builtins, validUserTheme, statusColors }")()

// Perceptual luma, 0..1 — enough to say "readable on dark" without a colour
// science library.
function luma(hex) {
    const s = hex.replace("#", "")
    return (0.299 * parseInt(s.substr(0, 2), 16)
        + 0.587 * parseInt(s.substr(2, 2), 16)
        + 0.114 * parseInt(s.substr(4, 2), 16)) / 255
}

// wallust 4.1.0-alpha, palette = "kmeans", dark. Two-tone art (navy + dusty
// rose): wallust interpolates a muted ramp, the mapping has to make it usable.
const naruto = {
    cursor: "#BC5F72", background: "#283343", foreground: "#BC5F72",
    color0: "#283343", color1: "#283343", color2: "#4B3A48", color3: "#4B3A48",
    color4: "#6B4557", color5: "#6B4557", color6: "#864F5B", color7: "#BC5F72",
    color8: "#3F4A5A", color9: "#283343", color10: "#4B3A48", color11: "#4B3A48",
    color12: "#6B4557", color13: "#6B4557", color14: "#864F5B", color15: "#BC5F72"
}
const p = paletteFromWallust(naruto)
assert.equal(p.background, "#303d50")   // background's own hue, slightly lifted
assert.equal(p.surface, "#394960")
assert.equal(p.surfaceHover, "#455773")
assert.equal(p.highlight, "#526889")
assert.equal(p.text, "#e0aeb8")         // dark foreground lifted for readability
assert.equal(p.subtext, "#8d7783")
assert.equal(p.accent, "#3973c6")       // navy side, pushed to a readable blue
assert.equal(p.accentAlt, "#c6397c")    // rose side, pushed to orchid
assert.equal(p.danger, "#c63958")       // nearest-to-red slot, pushed to rose-red
assert.equal(p.border, "#5d779c")

// Very dark art (mean ~13%): text must lift into the light end, and a palette
// with no red at all gets the constant error colour, not a boosted blue.
const forest = {
    cursor: "#4C6F82", background: "#01080F", foreground: "#4C6F82",
    color0: "#01080F", color1: "#01080F", color2: "#091E2B", color3: "#091E2B",
    color4: "#1F3744", color5: "#1F3744", color6: "#355261", color7: "#4C6F82",
    color8: "#2A3B47", color9: "#01080F", color10: "#091E2B", color11: "#091E2B",
    color12: "#1F3744", color13: "#1F3744", color14: "#355261", color15: "#4C6F82"
}
const d = paletteFromWallust(forest)
assert.equal(d.background, "#021222")
assert.equal(d.text, "#aecee0")
assert.equal(d.subtext, "#607582")
assert.equal(d.accent, "#3994c6")
assert.equal(d.danger, "#ff6b6b")

// Missing fields fall back to a usable dark palette instead of nulls.
const f = paletteFromWallust({})
assert.equal(f.background, dynamicFallback().background)
assert.match(f.accent, /^#[0-9a-f]{6}$/)
assert.match(f.dangerBg, /^#[0-9a-f]{6}$/)

// A grey palette stays grey, lifts its text, and never picks a near-black
// accent (nor sprouts a coloured accent out of zero saturation).
const g = paletteFromWallust({
    background: "#121313", foreground: "#a4a3a2",
    color1: "#C5C5C5", color2: "#5D5D5D", color3: "#3B3B3B",
    color4: "#181817", color5: "#A4A3A2", color6: "#999999"
})
assert.equal(g.accent, "#a4a3a2")
assert.equal(g.text, "#c8c7c6")
assert.notEqual(g.accentAlt, "#181817")
for (const k of ["background", "surface", "surfaceHover", "highlight", "accent",
    "accentAlt", "text", "subtext", "danger", "dangerBg", "dangerHover", "border"])
    assert.match(g[k], /^#[0-9a-f]{6}$/, k)

// Reverse map for `wallust cs`: every value is 6-digit hex (theme colours can
// carry alpha, e.g. builtin borders) and accents land on the ANSI slots. The
// bright half must be brighter than its base, never a dark background layer.
const w = wallustFromPalette({
    background: "#88aabbcc", accent: "#cba6f7", accentAlt: "#89b4fa", text: "#cdd6f4",
    subtext: "#a6adc8", danger: "#f38ba8", dangerHover: "#3d2040", highlight: "#585b70",
    surfaceHover: "#45475a", surface: "#313244"
})
assert.equal(w.background, "#aabbcc")
assert.equal(w.color6, "#cba6f7")
assert.equal(w.foreground, "#cdd6f4")
// Status slots: error = palette danger; success/warning pinned to the status
// inks (same values GTK/Qt/CLI use), never a theme accent.
assert.equal(w.color1, "#f38ba8")
assert.equal(w.color2, statusColors.success)
assert.equal(w.color3, statusColors.warning)
for (const k of Object.keys(w)) assert.match(w[k], /^#[0-9a-f]{6}$/, k)
for (const [base, bright] of [["color1", "color9"], ["color2", "color10"],
    ["color3", "color11"], ["color4", "color12"], ["color5", "color13"], ["color6", "color14"]])
    assert.ok(luma(w[bright]) > luma(w[base]), `${bright} brighter than ${base}`)

// Readability pass for dynamic: wallpapers (kmeans especially) cluster dark
// slots; the processed scheme keeps every key, lifts text/slots, and keeps
// the bright half above its base.
for (const [label, raw] of [["naruto", naruto], ["forest", forest]]) {
    const r = readableWallust(raw)
    assert.ok(r, label + ": processed scheme exists")
    for (const k of ["background", "foreground", "cursor",
        ...Array.from({ length: 16 }, (_, i) => "color" + i)])
        assert.match(r[k], /^#[0-9a-f]{6}$/, label + " " + k)
    assert.ok(luma(r.foreground) > 0.6, label + ": text readable on dark")
    assert.ok(luma(r.background) < 0.3, label + ": background stays dark")
    for (let i = 1; i <= 6; i++) {
        assert.ok(luma(r["color" + i]) > 0.3, `${label}: color${i} lifted`)
        assert.ok(luma(r["color" + (i + 8)]) > luma(r["color" + i]), `${label}: bright color${i + 8}`)
    }
    assert.equal(r.color1, paletteFromWallust(raw).danger, label + ": color1 = the error ink")
    assert.equal(r.color2, statusColors.success, label + ": color2 = success")
    assert.equal(r.color3, statusColors.warning, label + ": color3 = warning")
}
assert.equal(readableWallust(null), null)
assert.equal(readableWallust({}), null)
assert.equal(readableWallust({ background: "#123456" }), null)

// Every built-in theme must survive the same strict validation as a user file
// and have a unique name (the picker and `pill theme` read this table).
const names = new Set()
for (const b of builtins) {
    assert.ok(validUserTheme(b), "builtin valid: " + b.name)
    assert.ok(!names.has(b.name), "unique theme name: " + b.name)
    names.add(b.name)
}
assert.ok(names.size >= 18, "builtin themes present: " + names.size)

console.log("wallust mapping: OK")
