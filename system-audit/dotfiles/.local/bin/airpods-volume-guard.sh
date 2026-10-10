#!/usr/bin/env bash
#
# airpods-volume-guard.sh
#
# Monitors a Bluetooth audio sink (AirPods / earbuds) under PipeWire and
# guards its volume:
#
#   * If the volume reaches 100%, it is dropped to 60% immediately.
#   * Otherwise the last set (user chosen) level is kept as the baseline and
#     restored whenever the volume leaves the 60% clamp (and on reconnect,
#     so the device never comes back loud).
#   * The whole clamp/adjust cycle completes within 0.3 seconds (default poll
#     interval 0.10 s, actuation is a single wpctl call).
#
# State machine
#   tracking : mirrors the user volume. A reading of 100% moves us to guard.
#   guard    : pins the sink at the clamp target (60%). A 100% reading
#              (hardware echo from the earbuds) is re-clamped. A persistent
#              reading clearly away from the pin means the user moved the
#              volume deliberately; that level becomes the last set level and
#              is restored.
#
# Requirements: pipewire >= 1.0, wireplumber, wpctl, jq, awk, bluetoothctl;
# python3 is only needed to auto-resolve the MAC of a *disconnected* device.
#
# Usage:  $0 [MAC_ADDRESS] [-v]
#   MAC_ADDRESS  Bluetooth address of the device. Omitted = auto-resolved
#                (live sink -> single known BT device -> wireplumber cache).
#   -v           verbose stderr logging (normal logging goes to syslog).

set -u

# ---- configuration (overridable via environment) --------------------------
SINK_POLL_INTERVAL="${SINK_POLL_INTERVAL:-0.10}"  # s between volume polls
CLAMP_FRAC="${CLAMP_FRAC:-0.60}"                  # clamp target (60%)
ECHO_TOLERANCE="${ECHO_TOLERANCE:-0.02}"          # +/-2% tolerated as BT echo noise
ADOPT_SETTLE="${ADOPT_SETTLE:-0.15}"              # s to arbitrate a new level
REARM_SECONDS="${REARM_SECONDS:-2.5}"             # post-reconnect echo re-sync window

DEVICE_MAC=""
VERBOSE=0

# ---- logging --------------------------------------------------------------
syslog() { logger -t airpods-volume-guard "$*"; }
vlog() {
    [ "$VERBOSE" = 1 ] || return 0
    printf '[%s] %s\n' "$(date +%T.%3N)" "$*" >&2
}

# ---- helpers --------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $0 [MAC_ADDRESS] [-v]

  MAC_ADDRESS   Bluetooth address (AA:BB:CC:DD:EE:FF) of the device to guard.
                If omitted the device is resolved automatically.
  -v            verbose logging on stderr.
EOF
}

# All known Bluetooth sink MACs, live from the WirePlumber runtime.
list_runtime_sink_macs() {
    pw-dump 2>/dev/null | jq -r '
        .[]?
        | select(.type == "PipeWire:Interface:Node")
        | .info.props?
        | select(type == "object"
                 and ."media.class" == "Audio/Sink"
                 and (."api.bluez5.address" | type) == "string")
        | ."api.bluez5.address"
        | ascii_downcase'
}

# PipeWire node id of our Bluetooth sink, empty if it is not connected.
runtime_sink_id() {
    [ -n "$DEVICE_MAC" ] || return 1
    local out
    out="$(pw-dump 2>/dev/null | jq -r --arg mac \
        "$(printf '%s' "$DEVICE_MAC" | tr '[:upper:]' '[:lower:]')" '
            def norm: ascii_downcase | gsub("_"; ":");
            .[]?
            | select(.type == "PipeWire:Interface:Node")
            | . as $node | .info.props?
            | select(type == "object"
                     and ."media.class" == "Audio/Sink"
                     and (."api.bluez5.address" | type) == "string"
                     and (."api.bluez5.address" | norm) == $mac)
            | $node.id')"
    [ -n "$out" ] || return 1
    echo "$out" | head -1
}

# Single Bluetooth audio MAC from the WirePlumber cache (works while the
# device is disconnected, so the guard can wait for it to reappear).
resolve_mac_from_cache() {
    python3 -c '
import gzip, json, pathlib, sys
path = pathlib.Path.home() / ".cache/wireplumber/default-monitor"
files = sorted(path.glob("bluez_device.*.ruled.bin")) \
      + sorted(path.glob("bluez_device.*.bin"))
for p in files:
    try:
        raw = gzip.decompress(p.read_bytes())
    except Exception:
        continue
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            continue
        props = (obj.get("info") or {}).get("props") or {}
        if props.get("media.class") not in ("Audio/Sink", "Audio/Source") \
           and props.get("device.api") != "bluez5":
            continue
        mac = props.get("api.bluez5.address") \
              or (props.get("device.name") or "").split(".")[-1].replace("_", ":")
        if mac:
            print(mac.split(".")[-1].lower())
            sys.exit(0)
' 2>/dev/null | head -1
}

# Determine the Bluetooth MAC to guard.
find_bt_mac() {
    if [ -n "$DEVICE_MAC" ]; then
        echo "$DEVICE_MAC" | tr '[:upper:]' '[:lower:]'
        return 0
    fi
    # 1) the Bluetooth sink that is currently live in PipeWire
    local mac
    while read -r mac; do [ -n "$mac" ] && { echo "$mac"; return 0; }; done \
        < <(list_runtime_sink_macs)
    # 2) the single currently connected Bluetooth device
    local n=0
    while read -r mac; do [ -n "$mac" ] && n=$((n + 1)); done < <(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')
    if [ "$n" -eq 1 ]; then
        bluetoothctl devices Connected 2>/dev/null | awk '{print $2; exit}' | tr '[:upper:]' '[:lower:]'
        return 0
    fi
    # 3) the single known Bluetooth device (connected or paired)
    n=0
    while read -r mac; do [ -n "$mac" ] && n=$((n + 1)); done < <(bluetoothctl devices 2>/dev/null | awk '{print $2}')
    if [ "$n" -eq 1 ]; then
        bluetoothctl devices 2>/dev/null | awk '{print $2; exit}' | tr '[:upper:]' '[:lower:]'
        return 0
    fi
    # 4) the WirePlumber device cache (best effort)
    mac="$(resolve_mac_from_cache)"
    [ -n "$mac" ] && { echo "$mac"; return 0; }
    return 1
}

# Current volume as a fraction; empty string when the sink is gone.
current_volume_frac() {
    local v
    v="$(wpctl get-volume "$1" 2>/dev/null | awk '{print $2}')"
    [ -n "$v" ] && echo "$v"
}

is_100_pct() { awk -v a="$1" 'BEGIN{ exit !(a >= 0.9995) }'; }

frac_delta() {
    awk -v a="$1" -v b="$2" 'BEGIN{ d=a-b; if (d<0) d=-d; printf "%.6f", d }'
}

within_tolerance() {
    [ "$(awk -v a="$1" -v b="$2" -v t="$3" \
          'BEGIN{ d=a-b; if (d<0) d=-d; exit !(d <= t) }')" = 1 ]
}

as_percent() { awk -v a="$1" 'BEGIN{ printf "%d", a*100 + 0.5 }'; }

apply_volume() { wpctl set-volume "$1" "$2" 2>/dev/null; }

# ---- main loop ------------------------------------------------------------
main() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            -v) VERBOSE=1 ;;
            -h|--help) usage; exit 0 ;;
            *) [ -z "$DEVICE_MAC" ] && DEVICE_MAC="$arg" \
                || vlog "ignoring extra argument: $arg" ;;
        esac
    done

    DEVICE_MAC="$(find_bt_mac)" || {
        syslog "could not resolve a Bluetooth audio device MAC"
        exit 1
    }
    vlog "guarding device $DEVICE_MAC"

    local SINK_ID=""        # pipewire node id of the guarded sink
    local CUR=""            # latest volume fraction
    local LAST_USER=""      # last accepted (user chosen) level
    local STATE="tracking"  # tracking | guard
    local GUARD_TARGET=""   # volume pinned while in guard
    local DEVICE_SEEN=0     # was the sink up before
    local RECONNECTED=0     # sink reappeared after being gone
    local REARM_UNTIL=""    # end of post-reconnect echo re-sync window

    while :; do
        # (re)discover the sink whenever it is absent
        if [ -z "$SINK_ID" ]; then
            SINK_ID="$(runtime_sink_id || true)"
            if [ -n "$SINK_ID" ]; then
                vlog "sink connected (node id $SINK_ID)"
                if [ "$DEVICE_SEEN" = 1 ]; then
                    RECONNECTED=1
                    vlog "sink reconnected"
                fi
                DEVICE_SEEN=1
            else
                sleep "$SINK_POLL_INTERVAL"
                continue
            fi
        fi

        CUR="$(current_volume_frac "$SINK_ID")"
        if [ -z "$CUR" ]; then
            vlog "sink went away"
            SINK_ID=""
            continue
        fi

        if [ -z "$LAST_USER" ]; then
            LAST_USER="$CUR"
            vlog "initial volume $(as_percent "$CUR")% accepted as last set level"
        fi

        # On reconnect the device often boots at its own remembered volume
        # (sometimes maxed at 100%, sometimes the previous clamp pin).
        # Restore the last level the user had set so the sink never comes
        # back loud and always reflects the last set level.
        if [ "$RECONNECTED" = 1 ]; then
            RECONNECTED=0
            apply_volume "$SINK_ID" "$LAST_USER"
            STATE="tracking"
            REARM_UNTIL="$(awk -v t="$(date +%s.%N)" -v w="$REARM_SECONDS" \
                'BEGIN{ printf "%.3f", t + w }')"
            syslog "reconnected; restored last set level $(as_percent "$LAST_USER")%"
        fi

        # Right after a reconnect the earbuds re-sync their own chip volume,
        # which can briefly report 100% (it was maxed earlier and the chip
        # remembers it). Inside the rearm window that echo keeps the last
        # set level instead of being clamped.
        if is_100_pct "$CUR" && [ -n "$REARM_UNTIL" ]; then
            if awk -v n="$(date +%s.%N)" -v u="$REARM_UNTIL" 'BEGIN{ exit !(n < u) }'; then
                apply_volume "$SINK_ID" "$LAST_USER"
                STATE="tracking"
                vlog "reconnect re-sync echo 100%; kept last set level $(as_percent "$LAST_USER")%"
                sleep "$SINK_POLL_INTERVAL"
                continue
            else
                REARM_UNTIL=""
            fi
        fi

        if [ "$STATE" = "guard" ]; then
            # Pinning the volume at GUARD_TARGET.
            if is_100_pct "$CUR"; then
                # Earbud hardware echo of a maxed press: re-clamp.
                apply_volume "$SINK_ID" "$GUARD_TARGET"
                syslog "re-clamped 100% -> $(as_percent "$GUARD_TARGET")%"
            elif within_tolerance "$CUR" "$GUARD_TARGET" "$ECHO_TOLERANCE"; then
                : # on the pin (or within BT echo noise); hold quietly
            else
                # Clearly away from the pin. Give the echo a moment to settle;
                # if the deviation persists it is a deliberate user level.
                local cand="$CUR"
                sleep "$ADOPT_SETTLE"
                CUR="$(current_volume_frac "$SINK_ID")"
                if [ -z "$CUR" ]; then SINK_ID=""; continue; fi
                if is_100_pct "$CUR"; then
                    apply_volume "$SINK_ID" "$GUARD_TARGET"
                    syslog "re-clamped 100% -> $(as_percent "$GUARD_TARGET")%"
                elif within_tolerance "$CUR" "$GUARD_TARGET" "$ECHO_TOLERANCE"; then
                    apply_volume "$SINK_ID" "$GUARD_TARGET"
                    vlog "deviation settled back to the pin; re-applied $GUARD_TARGET"
                else
                    LAST_USER="$CUR"
                    apply_volume "$SINK_ID" "$LAST_USER"
                    STATE="tracking"
                    syslog "adopted new level $(as_percent "$LAST_USER")%; restored from $(as_percent "$GUARD_TARGET")%"
                fi
            fi
        else
            # tracking: mirror the user level, intercept 100%.
            if is_100_pct "$CUR"; then
                GUARD_TARGET="$CLAMP_FRAC"
                apply_volume "$SINK_ID" "$GUARD_TARGET"
                STATE="guard"
                syslog "volume 100% -> dropped to $(as_percent "$GUARD_TARGET")%"
            elif [ "$(frac_delta "$CUR" "$LAST_USER")" != "0.000000" ]; then
                LAST_USER="$CUR"
                vlog "tracking new level $(as_percent "$CUR")%"
            fi
        fi

        sleep "$SINK_POLL_INTERVAL"
    done
}

main "$@"