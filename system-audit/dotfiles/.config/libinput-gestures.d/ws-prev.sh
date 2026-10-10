#!/usr/bin/env bash
# 4-finger swipe LEFT -> move to the nearest EMPTY workspace behind and STOP.
export XDG_RUNTIME_DIR=/run/user/1000

cur=$(hyprctl activeworkspace -j 2>/dev/null | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])" 2>/dev/null)
[ -z "$cur" ] && hyprctl eval 'hl.dispatch(hl.dsp.focus({workspace="-1"}))' && exit

target=$(hyprctl -j workspaces 2>/dev/null | python3 -c "
import json,sys
cur=$cur
b=[]
for w in json.load(sys.stdin):
    if w['windows']==0 and w['id']<cur: b.append(w['id'])
print(max(b) if b else '')
" 2>/dev/null)

if [ -z "$target" ]; then
    hyprctl eval 'hl.dispatch(hl.dsp.focus({workspace="-1"}))'
    exit
fi

hyprctl eval "hl.dispatch(hl.dsp.focus({workspace=$target}))"
