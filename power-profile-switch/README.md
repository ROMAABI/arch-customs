# Power Profile Switch

Automatically switch Linux power profiles based on AC adapter connection status.

**Performance** mode on AC power → **Power Saver** mode on battery.

## How It Works

```
AC plug/unplug event
       │
       ▼
  udev ── ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="ADP1"
       │
       ▼
  systemd ── power-profile-switch.service (Type=oneshot)
       │
       ▼
  /usr/local/bin/power-profile-switch.sh
       │
       ├─ Reads /sys/class/power_supply/ADP1/online
       ├─ Calls powerprofilesctl set performance | power-saver
       ├─ Logs to journald
       └─ Desktop notification via notify-send
```

## Requirements

- **Arch Linux / EndeavourOS** (or any systemd-based distro)
- **power-profiles-daemon** (provides `powerprofilesctl`)
- **systemd** (for service management)
- **udev** (for device event detection)
- **Intel CPU** with `intel_pstate` driver (for performance/power-saver profiles)

Optional:
- **libnotify** (`notify-send`) for desktop notifications
- **Hyprland** / any graphical session (notifications auto-detect active session)

## Installation

### Automated

```bash
cd /home/spix/Projects/power-profile-switch
sudo ./install.sh
```

### Manual

```bash
sudo install -Dm755 power-profile-switch.sh /usr/local/bin/power-profile-switch.sh
sudo install -Dm644 power-profile-switch.service /etc/systemd/system/
sudo install -Dm644 99-power-profile-switch.rules /etc/udev/rules.d/
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
```

### Using Make

```bash
sudo make install
```

## Files

| File | Path | Purpose |
|---|---|---|
| `power-profile-switch.sh` | `/usr/local/bin/power-profile-switch.sh` | Core script: detects AC state, switches profile, logs, notifies |
| `power-profile-switch.service` | `/etc/systemd/system/power-profile-switch.service` | Systemd oneshot unit triggered by udev |
| `99-power-profile-switch.rules` | `/etc/udev/rules.d/99-power-profile-switch.rules` | udev rule matching ADP1 adapter change events |
| `install.sh` | — | Automated installer |
| `Makefile` | — | Build/install/uninstall automation |

## Verification

```bash
# Check current profile
powerprofilesctl get

# Monitor profile switches in real-time
journalctl -t power-profile-switch -f

# Test manually (simulates what udev triggers)
sudo /usr/local/bin/power-profile-switch.sh

# Verify udev rule
udevadm test /sys/class/power_supply/ADP1 2>&1 | grep -E 'power-profile|systemd'
```

## Uninstall

```bash
sudo make uninstall
# Or manually:
sudo rm -f /usr/local/bin/power-profile-switch.sh
sudo rm -f /etc/systemd/system/power-profile-switch.service
sudo rm -f /etc/udev/rules.d/99-power-profile-switch.rules
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
```

## Key Design Decisions

- **Instant, no polling** — udev events fire on kernel uevents the moment AC state changes
- **Asynchronous** — `SYSTEMD_WANTS` decouples udev from service execution, never blocking
- **Race-safe** — `flock -n` prevents concurrent runs from rapid plug/unplug
- **Idempotent** — script checks current profile before switching; no-op if already correct
- **Lightweight** — no extra daemons, no TLP, no python scripts running persistently
- **Compatible** — works alongside `power-profiles-daemon` without conflicts
- **Visible** — all actions logged to systemd journal; `notify-send` for desktop feedback

## Adapting to Different Hardware

If your AC adapter device is not `ADP1`, find it:

```bash
ls /sys/class/power_supply/
# Look for AC, ADP0, ADP1, ACAD, etc.
```

Then update the udev rule's `KERNEL` match and the script's `AC_ADAPTER` variable. The automated installer handles this detection.

## Troubleshooting

| Symptom | Check |
|---|---|
| No profile change on plug/unplug | `journalctl -t power-profile-switch -n 20` |
| udev rule not firing | `udevadm monitor --property --subsystem-match=power_supply` (watch events) |
| `powerprofilesctl` not found | `sudo pacman -S power-profiles-daemon` |
| Notifications not appearing | Ensure `libnotify` is installed and you have a graphical session |
