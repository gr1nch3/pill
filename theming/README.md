# Bubbles theming

Two independent lanes (PRD §6.3/§6.5):

## Fixed themes (7)

`ariadne`, `gruvbox`, `catppuccin`, `tokyonight`, `nord`, `rosepine`,
`everforest` — static color tables in `shell/components/Theme.qml`.
**Their palette never touches wallust.** Their eye palettes derive from the
same table (`Theme.eyeMoods`): idle = subtext, active = accent, alert = amber
(constant), error = danger. Single source of truth; no per-theme JSON duplicates.

## Dynamic theme

Wallpaper → `awww` → `wallust` → `~/.local/state/bubbles/scheme.json` →
`ThemeEngine` → `Theme._t` → same `eyeMoods` derivation. Bubbles runs wallust
on an aspect-preserving 512 px still (`~/.cache/bubbles/wallust-source.jpg`),
reads the full colourscheme wallust saves (`--save-scheme`) and maps it onto
its role palette: text is lifted from the foreground into a readable band, the
surface ladder is lightened from the background's own hue, and accents are
picked by hue/saturation (most vivid colour, a distinct second, nearest-red
for errors) then pushed into a readable band — so even two-tone, very dark, or
muted wallpapers yield usable accents. `kmeans` is the reference palette; it
keeps the wallpaper's own dominant colours.
`theming/wallust/` is the reference for the
app-retint side (kitty, btop). wallust's `{{wallpaper}}` variable points at
that still, not the original file. Light/dark (and the accent character) come
from wallust's `palette`/`style` settings — the old Bubbles Mode/Variant
pickers are gone; edit `~/.config/wallust/wallust.toml` instead. Bubbles
invokes wallust exactly as you would (templates run, terminals are recoloured,
`[hooks]` fire), so don't put a wallpaper-setting hook there — Bubbles owns the
wallpaper. Compositor theming (e.g. Hyprland border colors) is consumer-owned —
bubbles stops at its own surfaces.

## System theme sync (GTK / Qt / color-scheme)

`shell/services/SystemTheme.qml` mirrors the **resolved** palette — dynamic or
fixed — into the files GTK/Qt actually read, on every theme change:

- `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`: a
  `bubbles:generated` marker block with both GTK4/libadwaita and GTK3 colour
  names. The rest of each file is preserved, and the first write backs the
  original up under `~/.local/state/bubbles/backup/`.
- `~/.config/qt6ct/colors/bubbles.conf`: a full KDE colour scheme. Point
  `qt6ct.conf` at it (`color_scheme_path=`) and keep
  `QT_QPA_PLATFORMTHEME=qt6ct` in the session environment.
- `gsettings set org.gnome.desktop.interface color-scheme prefer-dark|light`,
  inferred from the palette background luminance.

Running apps pick GTK colours up on next launch. Qt5/Kvantum stay manual —
Bubbles reports them in Settings → Integrations rather than guessing a theme
SVG. The toggle is `Config.syncSystemTheme` (Settings → Integrations).

The wallust lane stays separate and user-owned: it runs for dynamic wallpapers
(via `wallust run`) and fixed themes (via `wallust cs`, fed a colourscheme
synthesized from Bubbles' resolved palette), writing whatever templates
`~/.config/wallust/wallust.toml` lists (kitty, btop, hypr, qutebrowser…).
Bubbles never edits that config; wallust creates a default one on first use.

## Fastfetch theming

`shell/services/Fastfetch.qml` writes `~/.config/fastfetch/config.jsonc` from
the resolved palette on every theme change (toggle in Settings → Fastfetch,
`Config.fastfetchEnabled`). Keys, title and output are coloured from the
palette; the logo and module list are user-configurable there too
(`Config.fastfetchLogo`: `auto` / `none` / a builtin name / `small:<name>` /
a file path; `Config.fastfetchModules`: comma-separated, empty = default set).
The file is generated wholesale (JSONC cannot be merged); a pre-existing config
is backed up once to `~/.local/state/bubbles/backup/fastfetch-config.jsonc`.

## Tool detection

`shell/services/Integrations.qml` probes every external binary once at startup.
Features whose tools are missing are hidden or inert instead of failing at
runtime, and the same list is shown live in Settings → Integrations and printed
by `bubbles doctor`.

## Greeter palette snapshot (SDDM)

SDDM runs pre-compositor and cannot watch a live wallpaper daemon:

1. The shell writes the resolved palette (plus eye/clock/font and
   lock/background settings) as a tiny QML component to
   `~/.cache/bubbles/GreeterPalette.qml` on every theme apply
   (`Theme.writeGreeterSnapshot`), and derives the lock/sign-in background in
   `~/.cache/bubbles/`: a bounded still (`lock-frame.jpg`; images resized,
   gifs and videos take their first frame) and, when the lock background is
   a gif, the gif itself (`greeter-wallpaper.gif`). The lock wallpaper can be
   picked independently of the desktop one (Wallpaper panel → `L` /
   "Set lock", reset in Settings → Backgrounds).
2. `bubbles greeter` (also run by `bubbles theme` / `update`) best-effort
   escalates the palette plus exactly one background to
   `/etc/xdg/bubbles/GreeterPalette.qml` and
   `/etc/xdg/bubbles/greeter-wallpaper.{jpg,gif}` (the other file is removed)
   in one pkexec call. The polkit agent is the Bubbles shell itself, so the
   shell must be up for the prompt to appear: `bubbles reload` waits for it,
   and pkexec runs with `--disable-internal-agent` so a dead shell fails fast
   instead of hanging in a terminal text prompt. A failed push leaves the
   previous files, with an honest message (ryoku §5 escalation-order lesson).
3. `sddm-theme/Main.qml` loads the palette with a `Loader` and draws the
   background (static `Image`, or `AnimatedImage` when the gif was installed)
   + scrim + pattern overlay, falling back to the embedded neutral palette if
   the files are missing — a cosmetic failure never blocks login.

Why QML and not JSON: Qt ≥ 6.5 blocks `XMLHttpRequest` reads of local files
unless `QML_XHR_ALLOW_FILE_READ=1` is set in the greeter environment. QML
component loading has no such block, so the greeter gets its palette without
touching `sddm.conf`.

`bubbles doctor` warns if this config is absent.

## Install

Install wallust first — `wallust-git` from the AUR (4.x, the version this
config targets) or a 3.5.x release, then from the repo checkout:

```bash
cd /path/to/bubbles
mkdir -p ~/.config/wallust/templates
cp theming/wallust/wallust.toml ~/.config/wallust/wallust.toml
cp theming/wallust/templates/* ~/.config/wallust/templates/
```

Merge into an existing config rather than clobbering it if you have one; on
3.5.x swap in the v3 palette keys noted at the top of the file. The wallust →
Bubbles role mapping has a runnable check: `node theming/wallust/test-mapping.mjs`.

## Adding themes (no code edit)

Drop a file in `~/.config/bubbles/themes/<name>.json` — the picker picks it up at
startup, and Settings → Theme → **Reload** re-reads the directory live. A user
theme with the same `name` as a built-in replaces it. `source` is used as the
seed for the eye/mood palette; `label` and `mode` are optional.

```json
{
  "name": "mytheme", "label": "My Theme", "source": "#ff7a45", "mode": "dark",
  "background": "#12100f", "surface": "#1c1917", "surfaceHover": "#26221f",
  "highlight": "#332d29", "accent": "#ff7a45", "accentAlt": "#ffb38a",
  "text": "#f5eeea", "subtext": "#a89f99", "danger": "#ff6b6b",
  "dangerBg": "#2a1515", "dangerHover": "#3d1e1e", "border": "#44a89f99"
}
```

A full example lives in `theming/themes/example.json`. `bubbles theme <name>`
accepts user themes as well.

## Adding app templates (wallust)

Bubbles runs your `~/.config/wallust/wallust.toml` for **every** theme — dynamic
wallpapers *and* fixed themes. Fixed themes re-run it via `wallust cs` with a
colourscheme synthesized from Bubbles' resolved palette, so template output
matches the shell instead of being re-derived from the wallpaper.

To retint another app, add a template entry + input file to the wallust config
(see `theming/wallust/templates/` for reference inputs; values are
`{{color0}}`…`{{color15}}`, `{{background}}`, `{{foreground}}`, `{{cursor}}`,
with filters like `{{color1 | lighten(0.2)}}`). Then either change theme or hit
Settings → Integrations → **Re-apply**. `bubbles doctor` prints how many
templates it found.
