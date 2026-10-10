#!/usr/bin/env bash
# 4-finger swipe up -> hymission toggle onlycurrentworkspace
export XDG_RUNTIME_DIR=/run/user/1000
hyprctl eval 'if hl.plugin and hl.plugin.hymission then hl.plugin.hymission.toggle("onlycurrentworkspace") else hl.notification.create({ text = "hymission not loaded - restart Hyprland", timeout = 3000 }) end'
