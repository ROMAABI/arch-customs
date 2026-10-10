#!/bin/bash
# SUPER+ALT+Q helper — close all windows on ALL Hyprland instances (all sessions).
# Called from keybinds.lua AFTER the pure-lua close of the current instance,
# so this only needs to cover any OTHER uwsm sessions.
#
# NOTE: `hyprctl dispatch closewindow` is broken on Hyprland 0.56 lua builds,
# so we use `hyprctl --instance $sig repl '<lua close-all>'` which works.

set -u

CLOSE_LUA='for _,w in ipairs(hl.get_windows()) do hl.dispatch(hl.dsp.window.close({window=w})) end; return "done"'

if ! command -v hyprctl >/dev/null || ! command -v jq >/dev/null; then
  exit 1
fi

CURRENT="${HYPRLAND_INSTANCE_SIGNATURE:-}"
mapfile -t instances < <(hyprctl instances -j 2>/dev/null | jq -r '.[].instance')

for sig in "${instances[@]}"; do
  [ -z "$sig" ] && continue
  # Current instance already handled in lua — skip to avoid double work
  # (harmless either way, but skip for speed)
  if [ -n "$CURRENT" ] && [ "$sig" = "$CURRENT" ]; then
    continue
  fi
  hyprctl --instance "$sig" repl "$CLOSE_LUA" >/dev/null 2>&1
done

exit 0
