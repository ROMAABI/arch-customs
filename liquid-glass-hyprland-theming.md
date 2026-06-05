# Liquid Glass Theming — Hyprland/HyDE

Translucent backgrounds, soft borders, and compositor blur applied to waybar, swaync, rofi, and kitty on top of the existing HyDE setup. Hyprland compositor config is at the old (pre-glass) baseline; only CSS / rasi / kitty config carries the glass effect.

## What's covered

| App | Method | Where |
|---|---|---|
| Hyprland compositor (blur layer rules) | already configured by HyDE | `~/.config/hypr/themes/theme.conf:31`, `~/.config/hypr/windowrules.conf:99-107` |
| Waybar | CSS alpha + border + box-shadow + compositor blur | `~/.config/waybar/user-style.css`, `~/.config/waybar/styles/liquid-glass.css` |
| Swaync | CSS alpha + hover states + compositor blur | `~/.config/swaync/style.css` |
| Rofi | rasi translucent backgrounds + soft borders | `~/.local/share/hyde/rofi/themes/style_1.rasi` (lines 166-186) |
| Kitty | `background_blur` + `dynamic_background_color` | `~/.config/kitty/kitty.conf` (lines 20-22) |

## Current state (final)

### Active glass changes (in effect)
- `~/.config/waybar/user-style.css` — `@import "styles/liquid-glass.css";` added at top. Import survives HyDE theme switches.
- `~/.config/waybar/style.css` — duplicate `@import "styles/liquid-glass.css";` removed from line 26 (HyDE-managed location).
- `~/.config/waybar/styles/liquid-glass.css` — `backdrop-filter` and `-webkit-backdrop-filter` lines removed (GTK CSS parser silently drops them anyway; real blur comes from the Hyprland compositor).
- `~/.config/swaync/style.css` — glass rules appended (translucent backgrounds, hover states, action/close buttons).
- `~/.local/share/hyde/rofi/themes/style_1.rasi` — rasi glass block appended at the end of the file (window / inputbar / element selected).
- `~/.config/kitty/kitty.conf` — `background_blur 20` + `dynamic_background_color yes` appended.

### Hyprland main config (reverted to old)
- `~/.config/hypr/userprefs.conf` — restored from `userprefs.conf.bak.glass`. The `decoration { }` block uses the original values: `rounding=10`, `blur.passes=2`, `blur.vibrancy=0.1696`, `blur.ignore_opacity=true`. No `shadow { }` sub-section. No custom top-level `general { }` block — windows pick up `border_size=3` and the wallpaper-adaptive purple borders from `themes/theme.conf`.

## Backups (`.bak.glass` files)

All pre-glass backups are preserved:

```
~/.config/hypr/userprefs.conf.bak.glass
~/.config/hypr/themes/theme.conf.bak.glass
~/.config/hypr/themes/wallbash.conf.bak.glass
~/.config/hypr/windowrules.conf.bak.glass
~/.config/kitty/kitty.conf.bak.glass
~/.local/share/hyde/rofi/themes/style_1.rasi.bak.glass
/tmp/theme.rasi.glass.bak                       (user file, untouched at original 8 lines)
```

## Reload commands

```bash
hyprctl reload                          # Hyprland compositor
pkill waybar && nohup waybar &          # Waybar
pkill -USR1 -x kitty                    # Kitty (live config reload)
pkill swaync && swaync &                # Swaync
# Rofi: re-launch from keybind (no live reload for rasi)
```

## Restore commands (revert to pre-glass)

```bash
# Hyprland main config (revert the revert)
cp ~/.config/hypr/userprefs.conf.bak.glass ~/.config/hypr/userprefs.conf
hyprctl reload

# Rofi (drop the rasi glass block)
cp ~/.local/share/hyde/rofi/themes/style_1.rasi.bak.glass \
   ~/.local/share/hyde/rofi/themes/style_1.rasi
```

For a full glass-off, manually delete the appended blocks from waybar / swaync / kitty (the `.bak.glass` files for those apps contain the pre-glass originals).

## Re-apply glass enhancements to hyprland (re-do what was reverted)

Edit `~/.config/hypr/userprefs.conf` and apply these changes to the `decoration { }` block:

```ini
decoration {
    rounding = 12                       # was 10
    active_opacity = 0.95
    inactive_opacity = 0.85
    blur {
        enabled = true
        size = 8
        passes = 3                      # was 2
        new_optimizations = true
        xray = false
        noise = 0.02                    # added
        contrast = 1.1                  # added
        brightness = 1.0                # added
        vibrancy = 0.2                  # was 0.1696
        vibrancy_darkness = 0.2         # added
        # remove: ignore_opacity = true
    }
    shadow {                            # added block
        enabled = true
        range = 20
        render_power = 3
        color = rgba(0,0,0,0.4)
    }
}
```

And add a new top-level `general { }` block to override the wallpaper-adaptive borders with thin white ones:

```ini
general {
    border_size = 1                     # was 3 (from theme.conf)
    col.active_border = rgba(ffffff33) rgba(ffffff11) 45deg
    col.inactive_border = rgba(ffffff08)
}
```

Then `hyprctl reload`.

## Known limitations

### Rofi — `border` and `border-radius` overridden by HyDE launch script

`~/.local/lib/hyde/rofilaunch.sh:73` hardcodes:

```bash
r_override="window {border: 2px; border-radius: 6px;} element {border-radius: 4px;}"
```

This is passed via `-theme-str` and has the highest priority — it overrides any `border` or `border-radius` set in any rasi file. Net effect: thin 2px border, 6px radius on the window, 4px on elements. Translucent backgrounds and border colors DO apply.

### Rofi — HyDE-managed file at risk

`~/.local/share/hyde/rofi/themes/style_1.rasi` is in the HyDE source tree. If you run `hyde-shell themeselect` or update HyDE, the file may be regenerated and the glass append wiped. Re-apply via:

```bash
# The last 21 lines of the .bak.glass are the glass append
tail -n 21 ~/.local/share/hyde/rofi/themes/style_1.rasi.bak.glass \
  >> ~/.local/share/hyde/rofi/themes/style_1.rasi
```

### Rasi syntax differences from CSS

Rasi 2.0 parses stricter than CSS. Glass rules were corrected to:

- **8-digit hex** (`#0f0f1973`) instead of `rgba(r,g,b,alpha)` — alpha = 0x73 / 255 ≈ 0.45
- **`border: 1px solid;`** + separate `border-color: #...;` — rasi treats `border` as width-only
- **No `box-shadow`** in rasi 2.0 (zero HyDE rasi files use it)
- **No `!important`** — causes a parse error

### Waybar import move

The `@import "styles/liquid-glass.css";` was moved from `~/.config/waybar/style.css:26` (HyDE-managed, clobbered on theme switch) to `~/.config/waybar/user-style.css:1` (HyDE-blessed user file, survives theme switches).

### Swaync pre-existing issues (not caused by this work)

- Duplicate `backdrop-filter: blur(12px);` lines at `~/.config/swaync/style.css:28-29`
- Dark fixed colors throughout the file — may look bad in light mode

### Backdrop-filter is not portable to GTK CSS / rasi

GTK CSS and rasi parsers silently drop `backdrop-filter` and `-webkit-backdrop-filter` properties. Real blur on waybar and swaync comes from the Hyprland compositor via the `layerrule = blur, ...` and `windowrule = blur, ...` lines in `themes/theme.conf` and `windowrules.conf` (already configured by HyDE, not touched by this work).

## File map

```
~/.config/
├── hypr/
│   ├── userprefs.conf                       (reverted to .bak.glass)
│   ├── userprefs.conf.bak.glass             (pre-glass backup)
│   ├── themes/
│   │   ├── theme.conf                       (unchanged; layerrule on line 31)
│   │   ├── theme.conf.bak.glass             (pre-glass backup)
│   │   ├── wallbash.conf                    (unchanged)
│   │   └── wallbash.conf.bak.glass          (pre-glass backup)
│   └── windowrules.conf                     (unchanged; layer rules on lines 99-107)
├── waybar/
│   ├── user-style.css                       (+ @import for liquid-glass.css)
│   ├── style.css                            (- duplicate @import from line 26)
│   └── styles/
│       └── liquid-glass.css                 (- backdrop-filter lines)
├── swaync/
│   └── style.css                            (+ glass rules appended)
├── kitty/
│   ├── kitty.conf                           (+ background_blur 20, dynamic_background_color yes)
│   └── kitty.conf.bak.glass                 (pre-glass backup)
└── rofi/
    └── theme.rasi                           (untouched, original 8-line state)
~/.local/share/hyde/rofi/themes/
├── style_1.rasi                             (+ rasi glass block, lines 166-186)
└── style_1.rasi.bak.glass                   (pre-glass backup)
```

## Quick sanity check

```bash
# Hyprland compositor values (should reflect old config: rounding=10, passes=2, border_size=3)
hyprctl getoption decoration:rounding
hyprctl getoption decoration:blur:size
hyprctl getoption decoration:blur:passes
hyprctl getoption general:border_size

# Rofi parses cleanly (no "error" / "fail" in dump)
timeout 3 rofi -theme style_1 -dump-theme 2>&1 | grep -iE "error|fail" | head -3

# Processes running with glass CSS / config
pgrep -lx waybar
pgrep -lx swaync
pgrep -lx kitty
```

## Workflow used

For each step: backup → apply minimal change → verify with live reload → confirm parse clean → reload command. No reboots, no full file rewrites, no touching HyDE-managed theme files (except the rasi append, which was the only place the rofi glass could go given the cascade).
