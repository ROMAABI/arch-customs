#!/usr/bin/env bash
# Supervisor: keep enabled hyprpm plugins loaded in the CURRENT Hyprland
# instance. Handles boot (Hyprland starts after default.target) and
# compositor restarts (new instance signature each time).
set -uo pipefail

sock_for() {
    ls -t "${XDG_RUNTIME_DIR}"/hypr/*/.socket.sock "${XDG_RUNTIME_DIR}"/hypr/*/.hyprland.sock 2>/dev/null | head -n 1
}

while true; do
    sock="$(sock_for)"
    if [ -n "$sock" ]; then
        export HYPRLAND_INSTANCE_SIGNATURE="$(basename "$(dirname "$sock")")"
        if ! hyprctl plugin list 2>/dev/null | grep -q "hymission"; then
            /usr/bin/hyprpm reload || true
        fi
    fi
    sleep 10
done
