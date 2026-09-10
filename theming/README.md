# Bubbles theming

Two independent lanes (PRD §6.3/§6.5):

## Fixed themes (7)

`ariadne`, `gruvbox`, `catppuccin`, `tokyonight`, `nord`, `rosepine`,
`everforest` — static color tables in `shell/components/Theme.qml`.
**They never touch matugen.** Their eye palettes derive from the same table
(`Theme.eyeMoods`): idle = subtext, active = accent, alert = amber (constant),
error = danger. Single source of truth; no per-theme JSON duplicates.

## Dynamic theme

Wallpaper → `awww` → `matugen` → `~/.local/state/pill/scheme.json` →
`ThemeEngine` → `Theme._t` → same `eyeMoods` derivation. The matugen config
below is the reference for the app-retint side (kitty, btop, qt6ct).
Compositor theming (e.g. Hyprland border colors) is consumer-owned — bubbles
stops at its own surfaces.

## Greeter palette snapshot (SDDM)

SDDM runs pre-compositor and cannot watch a live wallpaper daemon:

1. The shell writes the resolved palette to
   `~/.cache/bubbles/greeter-palette.json` on every theme apply
   (`Theme.writeGreeterSnapshot`).
2. `bubbles theme` / `bubbles update` best-effort escalate a copy to
   `/etc/xdg/bubbles/greeter-palette.json` via pkexec. Cancelled polkit prompt
   = the greeter keeps its previous palette, with an honest message (ryoku
   §5 escalation-order lesson).
3. `sddm-theme/Main.qml` reads that file and falls back to an embedded neutral
   palette if it's missing or corrupt — a cosmetic failure never blocks login.

`bubbles doctor` warns if this config is absent.

## Install

```bash
mkdir -p ~/.config/matugen/templates
cp theming/matugen/config.toml ~/.config/matugen/config.toml
cp theming/matugen/templates/* ~/.config/matugen/templates/
```

Merge into an existing config rather than clobbering it if you have one.
