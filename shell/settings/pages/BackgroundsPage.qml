import QtQuick
import "../../components"

import "../../services"
import "../../utils"
import "../controls"

SettingsPage {
    id: root

    property string greeterStatus: ""

    SettingSection { icon: "󰏘"; label: "PANEL PATTERNS" }

    SettingRow {
        icon: "󰏘"
        title: "Pattern"
        subtitle: "Behind large panels: launcher, wallpaper, clipboard, settings, theme, control center, media"
        SettingChips {
            options: [
                { value: "none", label: "None" },
                { value: "dots", label: "Dots" },
                { value: "grid", label: "Grid" },
                { value: "diagonal", label: "Slant" },
                { value: "cross", label: "Cross" },
                { value: "chevron", label: "Chevron" },
                { value: "noise", label: "Noise" }
            ]
            currentValue: Config.patternStyle
            onValueSelected: function(v) { Config.set("patternStyle", v) }
        }
    }

    SettingRow {
        icon: "󰏘"
        title: "Density"
        subtitle: "Pattern pitch"
        SettingChips {
            options: [
                { value: "sparse", label: "Sparse" },
                { value: "normal", label: "Normal" },
                { value: "dense", label: "Dense" }
            ]
            currentValue: Config.patternDensity
            onValueSelected: function(v) { Config.set("patternDensity", v) }
        }
    }

    // Live preview of the current pattern.
    Rectangle {
        width: parent.width
        height: 96
        radius: Theme.shape.radius.card
        color: Theme.surface
        border.width: Theme.shape.border.width
        border.color: Theme.border

        PatternBackground {
            anchors.fill: parent
            variant: Config.patternStyle
            spacing: Theme.patternSpacing
            strength: 0.09
            color: Theme.accent
            shape: "rounded"
            radius: parent.radius
        }
    }

    SettingSection { icon: "󰋩"; label: "LOCK & SIGN-IN" }

    SettingRow {
        icon: "󰋩"
        title: "Wallpaper"
        subtitle: "Show the lock wallpaper on the lock screen; gifs animate, videos show a still frame"
        SettingToggle {
            value: Config.lockWallpaper
            onValueEdited: function(v) { Config.set("lockWallpaper", v) }
        }
    }

    SettingRow {
        icon: "󰌾"
        title: "Lock wallpaper"
        subtitle: Config.lockWallpaperPath !== ""
            ? "Custom: " + Config.lockWallpaperPath.split("/").pop()
            : "Same as desktop — pick one in the Wallpaper panel and press L"
        SettingAction {
            visible: Config.lockWallpaperPath !== ""
            label: "Use desktop"
            onClicked: Config.set("lockWallpaperPath", "")
        }
    }

    SettingRow {
        icon: "󰏘"
        title: "Pattern overlay"
        subtitle: "Draw the pattern above the wallpaper on the lock screen"
        SettingToggle {
            value: Config.lockPattern
            onValueEdited: function(v) { Config.set("lockPattern", v) }
        }
    }

    SettingRow {
        icon: "󰏘"
        title: "Pattern style"
        subtitle: "Lock + sign-in overlay; Same follows the panel pattern"
        SettingChips {
            options: [
                { value: "", label: "Same" },
                { value: "none", label: "None" },
                { value: "dots", label: "Dots" },
                { value: "grid", label: "Grid" },
                { value: "diagonal", label: "Slant" },
                { value: "cross", label: "Cross" },
                { value: "chevron", label: "Chevron" },
                { value: "noise", label: "Noise" }
            ]
            currentValue: Config.lockPatternStyle
            onValueSelected: function(v) { Config.set("lockPatternStyle", v) }
        }
    }

    SettingRow {
        icon: "󰏘"
        title: "Pattern density"
        subtitle: "Lock + sign-in overlay pitch; Same follows the panel density"
        SettingChips {
            options: [
                { value: "", label: "Same" },
                { value: "sparse", label: "Sparse" },
                { value: "normal", label: "Normal" },
                { value: "dense", label: "Dense" }
            ]
            currentValue: Config.lockPatternDensity
            onValueSelected: function(v) { Config.set("lockPatternDensity", v) }
        }
    }

    SettingRow {
        icon: "󰒓"
        title: "Sign-in screen"
        subtitle: root.greeterStatus !== "" ? root.greeterStatus
            : "SDDM follows these settings; push the palette + wallpaper with polkit"
        SettingAction {
            label: "Sync Now"
            onClicked: {
                root.greeterStatus = "Syncing..."
                greeterCmd.run()
            }
        }
    }

    Text {
        width: parent.width
        text: "The sign-in screen can't read your home directory, so Bubbles copies the palette and one background file to /etc/xdg/bubbles: the animated gif when a gif is picked, otherwise a bounded still. `bubbles theme`/`update` do the same push."
        color: Theme.subtext
        font.pixelSize: Theme.font.size.small
        font.family: Theme.font.family
        wrapMode: Text.WordWrap
    }

    Cmd {
        id: greeterCmd
        command: ["bubbles", "greeter"]
        autorun: false
        onDone: function(code) {
            root.greeterStatus = code === 0
                ? "Palette + wallpaper pushed to the sign-in screen"
                : "Push failed (polkit cancelled or `bubbles` CLI missing)"
        }
    }
}
