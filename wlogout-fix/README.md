# wlogout-fix

Fix for the HyDE `logoutlaunch.sh` wlogout menu: buttons were invisible
(sent offscreen) on HiDPI / scaled displays, and the independent
margin tuning made them render either full-height or too small.

## Problem

The upstream script computed margins with a scale value that had the
decimal point stripped via `sed 's/\.//'`:

```sh
hypr_scale=$(hyprctl -j monitors | jq '... .scale' | sed 's/\.//')   # 1.2 -> 12
export mgn=$((y_mon * 28 / hypr_scale))                               # 1080*28/12 = 2520
```

On a 1920x1080 display at scale `1.2`, this produced a `2520px` margin —
larger than the logical screen (`900px`), pushing every button off-screen.
On top of that, wlogout lays out in **logical pixels** while
`x_mon`/`y_mon` (`monitor.width`/`height`) report **physical pixels**, so
the values passed through even after fixing the scale were wrong.

## Fix

1. Keep `hypr_scale` as a real float (do **not** strip the dot).
2. Convert physical resolution to logical pixels:

   ```sh
   lx_mon=$(awk "BEGIN{printf \"%d\", $x_mon / $hypr_scale}")
   ly_mon=$(awk "BEGIN{printf \"%d\", $y_mon / $hypr_scale}")
   ```

3. Base the tile margins on logical height with sane proportions
   (compact bar, ~2x label size):

   ```sh
   export mgn=$((ly_mon * 8 / 30))    # 240px on 900px logical height
   export hvr=$((ly_mon * 6 / 30))    # 180px
   export fntSize=$((y_mon * 2 / 100)) # 21px
   ```

With these values the menu renders as a readable horizontal bar
(≈ 480–550px tile height on a 900px screen).

## Files

- `logoutlaunch.sh` — patched launcher (drop into `~/.local/lib/hyde/`)
- `layout_1` — wlogout layout
- `style_1.css` — wlogout stylesheet (uses envsubst templates
  `$mgn`, `$hvr`, `$fntSize`, `$active_rad`, `$button_rad`)

## Install

```sh
cp logoutlaunch.sh ~/.local/lib/hyde/logoutlaunch.sh
mkdir -p ~/.config/wlogout
cp layout_1 style_1.css ~/.config/wlogout/
```

Trigger the menu with the HyDE default bind:

```
SUPER + SHIFT + Q
```