#!/usr/bin/env bash
# 3-finger swipe up -> hymission toggle (all workspaces)
export XDG_RUNTIME_DIR=/run/user/1000
hyprctl eval 'if hl.plugin and hl.plugin.hymission then hl.plugin.hymission.toggle() else hl.notification.create({ text = "hymission not loaded - restart Hyprland", timeout = 3000 }) end'
