# System Diagnosis: "A Stop Job Is Running…" During Shutdown

**Host:** `abix` | **OS:** Arch Linux / EndeavourOS | **systemd:** 260 | **DE:** Hyprland (UWSM + SDDM)

---

## Root Cause

**User lingering (`Linger=yes`) + `TimeoutStopSec=120s` on `user@.service`**

The user `spix` has lingering enabled. This means `user@1000.service` (the systemd user manager) persists even after logout. During shutdown, systemd must stop this lingering user manager, which had a **2-minute stop timeout**.

Inside `user@1000.service`, the inner `systemd --user` stops all child services sequentially. Each child service gets 90s to terminate. If one hangs (e.g., `gnome-keyring-daemon` — which crashed with `abort()` in the previous boot), the delay cascades up to the full timeout.

### Previous Boot Timeline

```
20:41:43  User runs: sudo systemctl restart sddm
         → SDDM stops, Hyprland session killed via UWSM
         → user@1000 keeps running (Linger=yes)
20:41:44  All user graphical session services stop
20:43:53 → 20:50:23  SDDM greeter crashes repeatedly (QML theme bug)
20:51:05  Another SDDM restart triggered
20:51:06  SDDM display server stops
         ┌──────────────────────────────────────┐
         │  "A STOP JOB IS RUNNING..."          │
         │  System waiting for user services    │
         │  to terminate (up to 2min)           │
         └──────────────────────────────────────┘
20:51:29  logind: "The system will reboot now!"
         → user@1000.service gets SIGTERM
20:51:35  user@1000.service: Deactivated successfully
20:51:36  Journal stops
```

## Fix Applied

| Setting | Before | After |
|---|---|---|
| `TimeoutStopSec` on `user@.service` | 120s (2 min) | **30s** |

### File Created

`/etc/systemd/system/user@.service.d/timeout.conf`

```ini
[Service]
TimeoutStopSec=30s
```

This is a systemd **drop-in** — it overrides only `TimeoutStopSec` without modifying the original unit file.

### Backup

- `/tmp/sisyphus-backup-systemd/user@.service.backup` — original unit template
- `/tmp/sisyphus-backup-systemd/timeout.conf` — copy of the drop-in

### Verification

```bash
systemctl show user@1000.service -p TimeoutStopUSec
# → TimeoutStopUSec=30s
```

- `user@1000.service` active ✓
- 23 system services running ✓
- 33 user services running ✓
- No new service failures introduced ✓

The 3 pre-existing failures (`mongodb.service`, `libinput-gestures`, `swaync`) are unrelated and unchanged.

## Secondary Issues (Not Modified)

| Issue | Severity | Notes |
|---|---|---|
| SDDM theme "sword" QML bug | Low | `TypeError: Cannot read property 'sName' of null` — greeter crashes on reboot |
| MongoDB log permissions | Low | `/var/log/mongodb/mongod.log` unwritable → service fails |
| gnome-keyring-daemon crash | Low | Crashed with `abort()` — assertion failure in glib |
| libinput-gestures on Wayland | Low | X11-only service, fails silently on Hyprland |

## Rollback

```bash
sudo rm -r /etc/systemd/system/user@.service.d/
sudo systemctl daemon-reload
```
