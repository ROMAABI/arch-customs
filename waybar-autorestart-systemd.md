# Waybar Auto-Restart via Systemd

**Host:** `abix` | **OS:** Arch Linux / EndeavourOS | **DE:** Hyprland (UWSM) | **Date:** 2026-06-03

---

## Problem

Waybar is the status bar, but it doesn't auto-restart when killed. Any `pkill waybar`, crash, or theme-switch restart left the bar gone until manual intervention.

Existing setup:
- `exec-once = ~/.config/waybar/smart-hide.sh` in `userprefs.conf` — only starts the visibility controller, NOT waybar itself
- `killall waybar || waybar` keybind in `keybindings.conf` — manual toggle, doesn't auto-recover
- No systemd unit for waybar — relied on HyDE autostart that was never actually starting it (waybar was missing from `ps`)

## Solution

Run waybar as a **systemd user service** with `Restart=always`. systemd will respawn it within 2 seconds of any death — `pkill`, segfault, OOM, anything.

### File Created

`~/.config/systemd/user/waybar.service`

```ini
[Unit]
Description=Waybar status bar
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/waybar
Restart=always
RestartSec=2
# Prevent tight crash loop
StartLimitInterval=60
StartLimitBurst=5

[Install]
WantedBy=default.target
```

### Commands Run

```bash
systemctl --user daemon-reload
systemctl --user enable waybar.service     # autostart at login
systemctl --user start waybar.service      # start now
```

### Verification

```bash
$ pgrep -x waybar
209779                    # ← waybar running

$ pkill -x waybar         # simulate crash/kill
$ sleep 3
$ pgrep -x waybar
210405                    # ← new PID, auto-restarted

$ systemctl --user is-active waybar.service
active
```

## Side-Fix: Keybind Conflict

The existing toggle keybind in `~/.config/hypr/keybindings.conf` was:

```ini
# OLD — caused duplicate waybar
bindd = ALT_R, Control_R, toggle waybar, exec, killall waybar || waybar
```

With systemd managing waybar, this caused a race: `killall` triggers systemd's 2s restart, but `|| waybar` also starts a new one immediately → 2 waybars on screen.

**Updated to:**

```ini
# NEW — clean restart via systemd
bindd = ALT_R, Control_R, toggle waybar, exec, systemctl --user restart waybar.service
```

## File Reference

| File | Status | Purpose |
|---|---|---|
| `~/.config/systemd/user/waybar.service` | Created | The systemd service |
| `~/.config/systemd/user/default.target.wants/waybar.service` | Symlink (auto) | Autostart hook |
| `~/.config/hypr/keybindings.conf:13` | Edited | Fixed keybind conflict |
| `~/.config/hypr/userprefs.conf:71` | **Untouched** | `smart-hide.sh` still runs (it's a visibility controller, not a starter) |

## Daily Use

| Command | What it does |
|---|---|
| `pkill waybar` | Kill it (auto-restarts in 2s) |
| `systemctl --user restart waybar.service` | Manual restart (clean) |
| `systemctl --user stop waybar.service` | Stop it (won't auto-restart) |
| `systemctl --user status waybar.service` | Status + restart count |
| `journalctl --user -u waybar.service -f` | Live logs |

## Connection to Theme Switcher

When using the theme-switcher script (option 2), the `pkill waybar` inside it now triggers systemd's auto-restart automatically. No more `killall && waybar &` boilerplate in the script — just `pkill -x waybar` and walk away.

## Notes

- `RestartSec=2` — brief delay to avoid tight crash loops
- `StartLimitBurst=5` / `StartLimitInterval=60` — if waybar crashes 5 times in 60s, systemd gives up (prevents runaway respawn on broken config)
- The service replaces the missing HyDE autostart path — waybar was actually not running before this fix
