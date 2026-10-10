#!/usr/bin/env bash
# 3-finger swipe right -> focus PREVIOUS window in the scroll carousel
export XDG_RUNTIME_DIR=/run/user/1000
hyprctl eval 'hl.dispatch(hl.dsp.layout("focus l"))'
