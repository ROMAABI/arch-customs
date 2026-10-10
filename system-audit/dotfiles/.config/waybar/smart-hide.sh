#!/usr/bin/env bash
set -euo pipefail

# Waybar Smart-Hide daemon
#  - Hides Waybar whenever there is at least one window open on the workspace
#    (and the cursor is not in the reveal zone).
#  - Shows it when the desktop is empty.
#  - REVEALS Waybar when the cursor touches the very top pixel edge.
#
# Cursor zones (pixel rule):
#   Reveal  Y <= 1        -> show waybar (reachable even with windows)
#   Dead    Y 2..40       -> do nothing (bar keeps current state; avoids flicker)
#   Hide    Y > 40        -> hide if windows open, otherwise show

STATE_FILE=/tmp/waybar_hidden
POLL_S=0.1

REVEAL_MAX=1   # Y <= 1  -> show waybar
DEAD_MAX=40    # Y <= 40 -> dead zone (no toggling); above this is the hide zone

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >>/tmp/smart-hide.log 2>/dev/null || true; }

is_hidden() { [ "$(cat "$STATE_FILE" 2>/dev/null)" = "hidden" ]; }
set_state() { printf '%s\n' "$1" >"$STATE_FILE"; }

get_window_count() {
    # Count windows on the ACTIVE workspace only (not all workspaces),
    # so an empty workspace shows the bar even if other workspaces have windows.
    hyprctl -j activeworkspace 2>/dev/null | awk -F'"windows": *' '/"windows"/{gsub(/[^0-9].*/, "", $2); print $2+0; exit}' | head -1
}

get_cursor_y() {
    # cursorpos returns "x, y"; grab the second token
    hyprctl cursorpos 2>/dev/null | sed -n 's/.*, *\([0-9]*\).*/\1/p' | head -1
}

waybar_running() { pgrep -x waybar >/dev/null 2>&1; }

# Show waybar (used when cursor touches the top edge or desktop is empty).
# SIGUSR2 -> show (configured via on-sigusr2: show in waybar config).
show_waybar() {
    if is_hidden && waybar_running; then
        pkill -SIGUSR2 -x waybar 2>/dev/null || true
        set_state shown
        log "show (reveal)"
    fi
}

# Hide waybar when windows are open. SIGUSR1 -> hide (on-sigusr1: hide).
check_hide() {
    local wins
    wins=$(get_window_count)
    if [ "$wins" -gt 0 ] && ! is_hidden && waybar_running; then
        pkill -SIGUSR1 -x waybar 2>/dev/null || true
        set_state hidden
        log "hide (windows=$wins)"
    fi
}

main() {
    rm -f "$STATE_FILE"
    set_state shown

    while true; do
        local y wins
        y=$(get_cursor_y)
        case "$y" in
            ''|*[!0-9]*) y=999 ;; # unparseable -> treat as deep (hide zone)
        esac

        wins=$(get_window_count)

        if [ "$wins" -eq 0 ]; then
            # DESKTOP EMPTY (on the active workspace): always show, no dead zone.
            show_waybar
        elif [ "$y" -le "$REVEAL_MAX" ]; then
            # REVEAL zone: cursor at the very top edge with windows open -> show.
            show_waybar
        elif [ "$y" -le "$DEAD_MAX" ]; then
            # DEAD zone: near the bar boundary, do nothing (prevents flicker).
            :
        else
            # HIDE zone: windows open and cursor well below the bar -> hide.
            check_hide
        fi
        sleep "$POLL_S"
    done
}

trap 'exit 0' TERM INT
log "smart-hide daemon started (window-count + cursor reveal)"
main
