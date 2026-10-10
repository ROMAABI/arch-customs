#!/usr/bin/env bash
# 3-finger swipe down -> toggle fullscreen on/off.
export XDG_RUNTIME_DIR=/run/user/1000
hyprctl eval '
local w = assert(hl.get_active_window(), "No active window")
if w.fullscreen == 0 then
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 1, client = 1, window = w }))
else
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0, window = w }))
end
'
