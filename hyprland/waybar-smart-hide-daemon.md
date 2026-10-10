# Waybar Smart-Hide Cursor Zones

**Host:** `abix` | **File:** `~/.config/waybar/smart-hide.sh` | **Date:** 2026-06-03

---

## Overview

`smart-hide.sh` is a daemon that auto-hides Waybar based on cursor position and workspace state. It uses `socat` to listen to Hyprland socket events and `pkill -SIGUSR1` to toggle Waybar visibility. A state file at `/tmp/waybar_hidden` tracks current visibility.

## Cursor Zones

```
Y=0  ┌──────────────┐
     │  Reveal zone  │  Y < 2    → show_waybar
Y=2  ├──────────────┤
     │              │
     │  Dead zone   │  Y 2–40   → do nothing (bar keeps current state)
     │  (browser)   │
     │              │
Y=40 ├──────────────┤
     │  Hide zone   │  Y > 40   → sync_visibility (hides if windows open)
     └──────────────┘
```

| Zone | Y range | Action | Purpose |
|------|---------|--------|---------|
| Reveal | 0–1 | `show_waybar` | Must hit very top edge to trigger |
| Dead | 2–40 | nothing | Browser tabs, address bar, waybar itself — safe zone |
| Hide | 41+ | `sync_visibility` | Hides only if windows exist on workspace |

## Key Design Decisions

- **`sync_visibility` instead of `hide_waybar`**: The hide trigger checks `get_window_count()` first. On an empty desktop, the bar stays visible even when cursor is far below.
- **100ms poll interval**: Fast enough for snappy response, low CPU overhead.
- **Dead zone prevents flicker**: Cursor can hover near the waybar boundary without toggling the bar on/off.
- **No `passthrough`**: Waybar remains fully interactive — click modules normally.

## Files

| File | Purpose |
|------|---------|
| `~/.config/waybar/smart-hide.sh` | The script |
| `/tmp/waybar_hidden` | State file ("hidden"/"shown") |
| `~/.config/waybar/smart-hide.sh.bak.20260603_154002` | Backup of previous version |
| `~/.config/systemd/user/waybar.service` | Systemd service for waybar auto-restart |

## Commands

```bash
# Restart smart-hide after editing
kill -9 $(ps aux | grep smart-hide.sh | grep -v grep | awk '{print $2}') 2>/dev/null
sleep 0.5
nohup setsid ~/.config/waybar/smart-hide.sh </dev/null >/tmp/smart-hide.log 2>&1 &

# Check it's running
ps aux | grep smart-hide.sh | grep -v grep

# Reload waybar config (no restart needed)
kill -SIGUSR2 $(pidof waybar)

# Waybar auto-restart via systemd
systemctl --user status waybar.service
```
