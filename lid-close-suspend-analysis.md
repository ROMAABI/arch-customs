# Lid-Close Suspend Analysis: Lag After Resume

## System
- **OS**: Arch Linux / EndeavourOS
- **WM**: Hyprland 0.55.1 (Wayland, Aquamarine 0.11.0 backend)
- **CPU**: Intel i5-1334U (Raptor Lake)
- **GPU**: Intel Iris Xe Graphics (device ID `8086:a7a1`, driver `i915`)
- **Host**: HP laptop (hostname: `abix`)

## Problem

| Scenario | Result |
|---|---|
| `systemctl suspend` *then* close lid | ✅ Smooth resume on lid open |
| Close lid directly (triggers suspend) | ❌ Laggy/stuttering after lid open |

---

## Root Cause

**The first suspend after each boot enters `s2idle` (modern standby) instead of `deep` sleep (S3).** The lag is caused by the i915 GPU not properly reinitializing after `s2idle` resume.

### Evidence: Kernel PM Log

```
21:36:08  kernel: PM: suspend entry (s2idle)    ← FIRST suspend → s2idle
23:29:09  kernel: PM: suspend entry (deep)       ← SECOND suspend → deep S3
```

Even though `/sys/power/mem_sleep` shows `s2idle [deep]` (deep is the current default), the very first suspend attempt uses `s2idle`. On Intel Alder Lake/Raptor Lake platforms, the i915 GPU driver is not fully initialized for deep sleep on the first cycle. systemd-sleep falls through `SuspendState=mem` → tries `standby` (s2idle).

### Compounding Factor: `LidSwitchIgnoreInhibited=yes`

The default logind config skips all inhibitor `PrepareForSleep` notifications when the lid triggers suspend. This means:

- hypridle, NetworkManager, UPower get **no signal** to prepare
- The GPU/compositor may be mid-frame when suspend hits
- The lid-close simultaneously triggers a **physical panel disconnect** (eDP HPD low) AND the suspend — creating a race in the i915 driver

Manual `systemctl suspend` respects inhibitors and enters deep sleep correctly.

### Full Timeline (boot session)

```
21:05:43  Boot
21:36:07  systemd-logind: "The system will suspend now!"
21:36:08  kernel: PM: suspend entry (s2idle)         ← shallow standby
21:36:08  kernel: Filesystems sync: 0.005s
-- [1h33m in s2idle] --
23:09:55  Lid closed → Lid opened → wake from s2idle
23:09:55  kernel: PM: suspend exit
23:29:09  Lid closed → systemd-logind triggers suspend
23:29:09  kernel: PM: suspend entry (deep)            ← true S3
23:38:56  ACPI: PM: Preparing S3 → Saving NVS → Waking from S3
23:38:56  kernel: PM: suspend exit                   ← clean resume
23:39:13  Lid closed → 23:39:17 Lid opened            ← quick cycle
```

---

## Diagnosed Configuration (read-only)

| Setting | Effective Value | Source |
|---|---|---|
| `HandleLidSwitch` | `suspend` (default) | `/etc/systemd/logind.conf` |
| `HandleLidSwitchExternalPower` | `suspend` (default) | same |
| `HandleLidSwitchDocked` | `ignore` (default) | same |
| `LidSwitchIgnoreInhibited` | `yes` (default) | **skips inhibitor path** |
| `SuspendState` | `mem standby freeze` (default) | `/etc/systemd/sleep.conf` |
| `mem_sleep` | `s2idle [deep]` | `/sys/power/mem_sleep` |
| CPU governor | `powersave` (intel_pstate active) | Normal for Intel HWP |
| i915 module params | all default/empty | `/sys/module/i915/parameters/` |
| Kernel cmdline | `BOOT_IMAGE=/vmlinuz-linux ... loglevel=3` | **no PM params** |
| Sleep hooks | none | `/usr/lib/systemd/system-sleep/` empty |
| Custom lid scripts | none | `~/.config/hypr/scripts/`, `~/.local/bin/` checked |

### Inhibitors (delay mode — all ignored on lid-close)

| WHO | WHY |
|---|---|
| NetworkManager | Turn off networks |
| rtkit-daemon | Demote realtime scheduling |
| UPower | Pause device polling |
| hypridle | Before_sleep handling |

---

## Why Manual Suspend Works

1. System has been running → GPU driver is warm → **deep sleep succeeds**
2. `systemctl suspend` goes through systemd's coordinated path → **inhibitors respected**
3. Display is ON and stable during suspend entry → clean GPU state save
4. Resume from S3 → full GPU reinitialization → everything clean

## Why Lid-Close Is Laggy

1. Often the **first suspend** after boot → enters **s2idle**
2. `LidSwitchIgnoreInhibited=yes` → **no coordination** with compositor or apps
3. Lid-close triggers **simultaneous panel disconnect + suspend** → i915 race
4. `s2idle` resume → GPU in degraded state (stale DC states, PSR, GuC freq scaling)

---

## Fix

### Option 1: Force deep sleep — most reliable

```bash
# /etc/default/grub — add to GRUB_CMDLINE_LINUX:
# GRUB_CMDLINE_LINUX="... mem_sleep_default=deep"

grub-mkconfig -o /boot/grub/grub.cfg
# reboot required
```

This prevents the kernel from ever defaulting to `s2idle`, even on the first suspend.

### Option 2: Respect inhibitors on lid-close (immediate, no reboot)

Create `/etc/systemd/logind.conf.d/lid.conf`:
```ini
[Login]
LidSwitchIgnoreInhibited=no
```
```bash
systemctl restart systemd-logind
```

### Option 3: Force deep via systemd (no reboot)

Create `/etc/systemd/sleep.conf.d/deep.conf`:
```ini
[Sleep]
MemorySleepMode=deep
```

### Option 4: Disable i915 display C-states (reduces s2idle glitches)

Create `/etc/modprobe.d/i915.conf`:
```options i915 enable_dc=0```
```bash
mkinitcpio -P
# reboot required
```

---

## Verification Commands

```bash
# Current sleep mode default
cat /sys/power/mem_sleep

# What mode each suspend actually used
journalctl -b -k | grep "PM: suspend entry"

# Effective logind config
systemd-analyze cat-config systemd/logind.conf

# Active inhibitors
systemd-inhibit --list

# Live lid state
cat /proc/acpi/button/lid/LID0/state

# Monitor lid events in real time
journalctl -u systemd-logind -f | grep -i lid
```
