#!/usr/bin/env fish
# ~/.local/bin/adb-auto-watch.fish - always-on ADB USB watcher -> WiFi (tcpip 5555)
# Polls `adb devices` every 2s. No root / udev needed.
# - USB plugged -> enable tcpip, connect WiFi, update cache
# - No USB -> keep cached WiFi connected (retry every 10s)

set CACHE_FILE ~/.cache/adb-last-ip
set PORT 5555
set POLL 2
set CACHED_RETRY 10

adb start-server >/dev/null 2>&1

function get_usb_serial
    adb devices 2>/dev/null | awk '$2=="device" && $1 !~ /:/ {print $1; exit}'
end

function wifi_ok
    adb devices 2>/dev/null | grep -qE ':[0-9]+[[:space:]]+device'
end

function get_phone_ip -a serial
    set -l ip (timeout 8 adb -s $serial shell ip route 2>/dev/null | grep wlan | grep -oE 'src [0-9.]+' | grep -oE '[0-9.]+' | head -n1 | string trim)
    if test -z "$ip"
        set ip (timeout 8 adb -s $serial shell ip route 2>/dev/null | grep -oE 'src [0-9.]+' | grep -oE '[0-9.]+' | head -n1 | string trim)
    end
    if test -z "$ip"
        set ip (timeout 8 adb -s $serial shell "ip -o -4 addr show wlan1 wlan0 2>/dev/null" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+' | cut -d/ -f1 | head -n1 | string trim)
    end
    echo (string trim $ip)
end

function do_usb_connect -a serial
    echo "USB device: $serial"
    set -l phone_ip (get_phone_ip $serial)
    if test -z "$phone_ip"
        echo "Could not get phone IP. Unlock phone, enable WiFi, allow USB debugging." >&2
        return 1
    end
    if test -f $CACHE_FILE
        set -l old_ip (cat $CACHE_FILE | string trim)
        if test -n "$old_ip"; and test "$old_ip" != "$phone_ip"
            echo "IP changed $old_ip -> $phone_ip, disconnecting stale..."
            adb disconnect $old_ip:$PORT >/dev/null 2>&1
        end
    end
    for stale in (adb devices 2>/dev/null | awk '$2 != "device" && $1 ~ /:5555/ {print $1}')
        echo "Disconnecting stale $stale..."
        adb disconnect $stale >/dev/null 2>&1
    end
    echo $phone_ip >$CACHE_FILE
    echo "Phone IP: $phone_ip"
    timeout 10 adb -s $serial tcpip $PORT
    sleep 3
    for j in (seq 1 5)
        timeout 10 adb connect $phone_ip:$PORT
        and break
        echo "connect try $j failed, retrying..." >&2
        sleep 2
    end
    adb devices
    return 0
end

set last_usb ""
set last_cached_try 0

echo "adb-auto-watch started (poll $POLL"s", cached retry $CACHED_RETRY"s")"

while true
    set serial (get_usb_serial)

    if test -n "$serial"
        if test "$serial" != "$last_usb"; or not wifi_ok
            do_usb_connect $serial
        end
        set last_usb $serial
        set last_cached_try 0
    else
        if test -n "$last_usb"
            echo "USB unplugged (was $last_usb), falling back to WiFi..."
        end
        set last_usb ""
        if not wifi_ok
            if test -f $CACHE_FILE
                set -l cached (cat $CACHE_FILE | string trim)
                if test -n "$cached"
                    set now (date +%s)
                    if test (math "$now - $last_cached_try") -ge $CACHED_RETRY
                        echo "No USB, trying cached $cached:$PORT..."
                        timeout 10 adb connect $cached:$PORT
                        set last_cached_try $now
                    end
                end
            end
        else
            # WiFi healthy, update cache from live connection so DHCP changes don't go stale
            set -l live (adb devices 2>/dev/null | awk '$2=="device" && $1 ~ /:/ {print $1; exit}' | cut -d: -f1 | string trim)
            if test -n "$live"; and test -f $CACHE_FILE
                set -l cached (cat $CACHE_FILE | string trim)
                if test "$live" != "$cached"
                    echo "Updating cache $cached -> $live"
                    echo $live >$CACHE_FILE
                end
            end
        end
    end
    sleep $POLL
end
