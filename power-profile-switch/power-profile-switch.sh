#!/bin/bash
# Power Profile Switch Daemon
# Automatically switches power profiles based on AC adapter connection
#
# Architecture:
#   1. udev detects AC adapter change events
#   2. udev triggers systemd service (power-profile-switch.service)
#   3. systemd runs this script
#   4. Script checks online state -> sets profile -> logs -> notifies
#
# Profiles: performance (AC) / power-saver (battery)
#
# Dependencies: power-profiles-daemon, systemd, udev
# Optional: libnotify (desktop notifications)

set -euo pipefail

# --- Configuration --------------------------------------------------------
readonly AC_ADAPTER="ADP1"
readonly PROFILE_AC="performance"
readonly PROFILE_BATTERY="power-saver"
readonly LOCK_FILE="/run/lock/power-profile-switch.lock"

# --- Lock (prevent concurrent runs from rapid plug/unplug) ----------------
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# --- Detect current AC state ---------------------------------------------
ONLINE=$(cat "/sys/class/power_supply/${AC_ADAPTER}/online" 2>/dev/null || echo "0")

if [ "$ONLINE" = "1" ]; then
    TARGET_PROFILE="$PROFILE_AC"
    STATE_LABEL="AC power"
else
    TARGET_PROFILE="$PROFILE_BATTERY"
    STATE_LABEL="Battery power"
fi

# --- Skip if already on target profile -----------------------------------
CURRENT_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "unknown")
if [ "$CURRENT_PROFILE" = "$TARGET_PROFILE" ]; then
    logger -t power-profile-switch "${STATE_LABEL}: already on ${TARGET_PROFILE}, no change needed"
    exit 0
fi

# --- Switch profile ------------------------------------------------------
logger -t power-profile-switch "${STATE_LABEL}: switching profile to ${TARGET_PROFILE} (was ${CURRENT_PROFILE})"
powerprofilesctl set "$TARGET_PROFILE"
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    logger -t power-profile-switch "ERROR: failed to set profile to ${TARGET_PROFILE} (exit code ${EXIT_CODE})"
    exit $EXIT_CODE
fi

# --- Optional: Desktop notification to active user session ---------------
notify_user() {
    local summary="$1" body="$2"
    for u in /run/user/*/; do
        uid="${u%/}"
        uid="${uid##*/}"
        [ -z "$uid" ] && continue
        user=$(id -un "$uid" 2>/dev/null) || continue

        if command -v loginctl &>/dev/null; then
            has_seat=$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$uid" '$3 == u && /seat/ {print; exit}')
            [ -z "$has_seat" ] && continue
        fi

        bus="unix:path=/run/user/$uid/bus"
        display=":0"
        if su "$user" -c "DBUS_SESSION_BUS_ADDRESS=$bus DISPLAY=$display notify-send -a 'Power Profile' '$summary' '$body'" 2>/dev/null; then
            break
        fi
    done
}

if [ "$TARGET_PROFILE" = "$PROFILE_AC" ]; then
    notify_user "Power Profile" "AC connected -> ${PROFILE_AC}"
else
    notify_user "Power Profile" "Battery -> ${PROFILE_BATTERY}"
fi

exit 0
