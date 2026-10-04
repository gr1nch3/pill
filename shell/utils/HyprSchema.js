.pragma library
// UI metadata for the Hyprland runtime options: one row per control, grouped
// by settings page. The service only reads keys; the pages render this.

var groups = [
    {
        name: "General",
        page: "hyprland",
        controls: [
            { key: "general:gaps_in",     label: "Gaps In",     icon: "󰡌", kind: "int", min: 0, max: 100, step: 1 },
            { key: "general:gaps_out",    label: "Gaps Out",    icon: "󰡎", kind: "int", min: 0, max: 100, step: 1 },
            { key: "general:border_size", label: "Border Size", icon: "󰃇", kind: "int", min: 0, max: 20,  step: 1 }
        ]
    },
    {
        name: "Decoration",
        page: "hyprland",
        controls: [
            { key: "decoration:rounding",         label: "Rounding",         icon: "󰘇", kind: "int",     min: 0,   max: 40, step: 1 },
            { key: "decoration:blur:enabled",     label: "Blur",             icon: "󰂵", kind: "bool" },
            { key: "decoration:blur:size",        label: "Blur Size",        icon: "󰂵", kind: "int",     min: 1,   max: 20, step: 1 },
            { key: "decoration:blur:passes",      label: "Blur Passes",      icon: "󰂵", kind: "int",     min: 1,   max: 5,  step: 1 },
            { key: "decoration:shadow:enabled",   label: "Shadows",          icon: "󰘷", kind: "bool" },
            { key: "decoration:shadow:range",     label: "Shadow Range",     icon: "󰘷", kind: "int",     min: 0,   max: 60, step: 1 },
            { key: "decoration:dim_inactive",     label: "Dim Inactive",     icon: "󰃠", kind: "bool" },
            { key: "decoration:dim_strength",     label: "Dim Strength",     icon: "󰃠", kind: "percent", min: 0,   max: 1,  step: 0.05 },
            { key: "decoration:active_opacity",   label: "Active Opacity",   icon: "󰍹", kind: "percent", min: 0.1, max: 1,  step: 0.05 },
            { key: "decoration:inactive_opacity", label: "Inactive Opacity", icon: "󰍹", kind: "percent", min: 0.1, max: 1,  step: 0.05 }
        ]
    },
    {
        name: "Animations",
        page: "hyprland",
        controls: [
            { key: "animations:enabled", label: "Animations", icon: "󰗘", kind: "bool" }
        ]
    },
    {
        name: "Keyboard",
        page: "input",
        controls: [
            { key: "input:kb_layout",  label: "Layout",       icon: "󰌌", kind: "str" },
            { key: "input:kb_variant", label: "Variant",      icon: "󰌌", kind: "str" },
            { key: "input:repeat_rate", label: "Repeat Rate",  icon: "󰌌", kind: "int", min: 0, max: 100, step: 5 },
            { key: "input:repeat_delay", label: "Repeat Delay", icon: "󰌌", kind: "int", min: 100, max: 1000, step: 50 }
        ]
    },
    {
        name: "Pointer & Touchpad",
        page: "input",
        controls: [
            { key: "input:sensitivity",             label: "Sensitivity",     icon: "󰍽", kind: "float",  min: -1, max: 1, step: 0.1 },
            { key: "input:accel_profile",           label: "Accel Profile",   icon: "󰍽", kind: "str" },
            { key: "input:touchpad:natural_scroll", label: "Natural Scroll",  icon: "󰍽", kind: "bool" },
            { key: "input:touchpad:tap-to-click",   label: "Tap to Click",    icon: "󰍽", kind: "bool" },
            { key: "input:touchpad:scroll_factor",  label: "Scroll Factor",   icon: "󰍽", kind: "float", min: 0.1, max: 3, step: 0.1 }
        ]
    }
]
