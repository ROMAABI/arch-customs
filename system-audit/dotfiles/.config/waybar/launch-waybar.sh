#!/usr/bin/env bash
set -euo pipefail

UNIT="hyde-Hyprland-bar.service"

# Wait for Hyprland (starts after default.target): need its IPC socket AND a
# Wayland socket. WAYLAND_DISPLAY may not be imported into the systemd user
# environment yet at this point, so derive the display from the socket dir.
for i in $(seq 1 450); do
    [ -n "$(ls "${XDG_RUNTIME_DIR}"/hypr/*/.socket.sock "${XDG_RUNTIME_DIR}"/hypr/*/.hyprland.sock 2>/dev/null | head -n 1)" ] && break
    sleep 0.2
done
WL_DISPLAY="${WAYLAND_DISPLAY:-}"
if [ -z "$WL_DISPLAY" ]; then
    WL_SOCK="$(ls -t "${XDG_RUNTIME_DIR}"/wayland-* 2>/dev/null | grep -E '/wayland-[0-9]+$' | head -n 1)"
    [ -n "$WL_SOCK" ] && WL_DISPLAY="$(basename "$WL_SOCK")"
fi
WL_DISPLAY="${WL_DISPLAY:-wayland-1}"

# Wait for HyDE's generated includes to settle. At login the theme machinery
# (hyde waybar.py) rewrites includes.json/CSS; starting the bar mid-write
# loads a partial config with custom/* modules hidden.
INC_FILE="$HOME/.config/waybar/includes/includes.json"
for _ in $(seq 1 15); do
    m1="$(stat -c %Y "$INC_FILE" 2>/dev/null)"
    sleep 2
    m2="$(stat -c %Y "$INC_FILE" 2>/dev/null)"
    [ -n "$m1" ] && [ "$m1" = "$m2" ] && break
done

# Idempotent: if the unit is already active (HyDE started it, or we did),
# do nothing — avoid duplicate instances.
if systemctl --user is-active --quiet "$UNIT" 2>/dev/null; then
    exit 0
fi

# Create the supervised transient unit. Restart=always + RestartSec=1
# ensures waybar comes back after crashes without triggering the tray
# SIGUSR2 re-registration bug. Display env is passed explicitly because the
# systemd user environment may not have it yet this early in boot.
systemd-run --user \
    --unit="$UNIT" \
    --slice=app-graphical.slice \
    --setenv=WAYLAND_DISPLAY="$WL_DISPLAY" \
    --setenv=XDG_CURRENT_DESKTOP=Hyprland \
    --property=Type=exec \
    --property=ExitType=cgroup \
    --property=Restart=always \
    --property=RestartSec=1 \
    --property=PartOf=graphical-session.target \
    --quiet \
    -- waybar
