#!/usr/bin/env bash
# systemd wrapper: start libinput-gestures only after Hyprland is up, with the
# instance environment derived at exec time (manager env may not have it yet).
set -uo pipefail

sock=""
for _ in $(seq 1 450); do
    sock=$(ls -t "${XDG_RUNTIME_DIR}"/hypr/*/.socket.sock "${XDG_RUNTIME_DIR}"/hypr/*/.hyprland.sock 2>/dev/null | head -n 1)
    [ -n "$sock" ] && break
    sleep 0.2
done
[ -n "$sock" ] || { echo "no Hyprland socket found" >&2; exit 1; }

export HYPRLAND_INSTANCE_SIGNATURE
HYPRLAND_INSTANCE_SIGNATURE="$(basename "$(dirname "$sock")")"

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    wl_sock="$(ls -t "${XDG_RUNTIME_DIR}"/wayland-* 2>/dev/null | grep -E '/wayland-[0-9]+$' | head -n 1)"
    [ -n "$wl_sock" ] && export WAYLAND_DISPLAY="$(basename "$wl_sock")"
fi
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"

# Supervise: if the compositor restarts (new instance socket), exit so systemd
# restarts us with a fresh environment (gesture actions inherit this env).
/usr/bin/libinput-gestures &
DPID=$!
while kill -0 "$DPID" 2>/dev/null; do
    cur="$(ls -t "${XDG_RUNTIME_DIR}"/hypr/*/.socket.sock "${XDG_RUNTIME_DIR}"/hypr/*/.hyprland.sock 2>/dev/null | head -n 1)"
    if [ -n "$cur" ] && [ "$cur" != "$sock" ]; then
        kill "$DPID" 2>/dev/null
        wait "$DPID" 2>/dev/null
        exit 0
    fi
    sleep 5
done
wait "$DPID"
