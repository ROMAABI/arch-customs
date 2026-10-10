# Arch Custom Configs & Fixes

A personal collection of custom **Arch Linux** configs, systemd units, and
troubleshooting notes for a **Hyprland / HyDE** setup (host: `abix`, user
`spix`).

## Layout

| Path | What it is |
|---|---|
| `power-profile-switch/` | Systemd-based power-profile switching (udev rule + service + installer) |
| `wlogout-fix/` | Patch for HyDE `logoutlaunch.sh` — logout menu invisible on scaled displays |
| `hyprland/` | Hyprland/HyDE display, theming, and waybar notes + screen shader |
| `docs/` | System analyses, on-demand service notes, and session logs |

## Installable

### power-profile-switch

Installs a `udev` rule + systemd service that switches the CPU power
profile on AC/battery events. Runs on plug/unplug; enable the service
to also correct the profile at boot.

```sh
cd power-profile-switch
sudo bash ./install.sh
sudo systemctl enable power-profile-switch.service
```

### wlogout-fix

Fixes the HyDE logout menu (`SUPER + SHIFT + Q`) that failed to render
on HiDPI / scaled displays.

```sh
cp wlogout-fix/logoutlaunch.sh ~/.local/lib/hyde/logoutlaunch.sh
mkdir -p ~/.config/wlogout
cp wlogout-fix/layout_1 wlogout-fix/style_1.css ~/.config/wlogout/
```

See `wlogout-fix/README.md` for full details. `wlogout-fix/upstream-reference/`
holds unmodified upstream scripts for diffing only.

## hyprland/

| File | What it is |
|---|---|
| `hyprland/waybar-autorestart-systemd.md` | Auto-restarting Waybar via systemd |
| `hyprland/waybar-smart-hide-daemon.md` | Smart-hide cursor zones for Waybar |

## docs/

| File | What it is |
|---|---|
| `docs/lid-close-suspend-analysis.md` | Diagnoses lag after lid-close suspend & resume |
| `docs/systemd-shutdown-stop-job-fix.md` | Diagnosis of "A Stop Job Is Running…" during shutdown |
| `docs/llama-server-on-demand-proxy.md` | On-demand `llama-server` proxy wrapper |
| `docs/openclaw-removal-log.md` | Session log of removing OpenClaw traces |

## License

Private — for personal use.
