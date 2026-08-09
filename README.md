# Arch Custom Configs & Fixes

A personal collection of custom **Arch Linux** configs, systemd units, and
troubleshooting notes for a **Hyprland / HyDE** setup (host: `abix`, user
`spix`).

## Contents

| Path | What it is |
|---|---|
| `power-profile-switch/` | Systemd-based power-profile switching (UDEV rules + timer + Makefile installer) |
| `wlogout-fix/` | Patch for HyDE `logoutlaunch.sh` — logout menu invisible on scaled displays |
| `amoled-display-hyprland-enhancement.md` | AMOLED/OLED display tuning notes for Hyprland |
| `oled-amoled-enhance.frag` | Hyprland screen shader — OLED-style color profile (gamma/contrast/saturation/black-lift) |
| `liquid-glass-hyprland-theming.md` | Liquid-glass theming notes for Hyprland/HyDE |
| `lid-close-suspend-analysis.md` | Diagnoses lag after lid-close suspend & resume |
| `systemd-shutdown-stop-job-fix.md` | Diagnosis of "A Stop Job Is Running…" during shutdown |
| `waybar-autorestart-systemd.md` | Auto-restarting Waybar via Systemd |
| `waybar-smart-hide-daemon.md` | Smart-hide cursor zones for Waybar |
| `llama-server-on-demand-proxy.md` | On-demand `llama-server` proxy wrapper |
| `openclaw-removal-log.md` | Session log of removing OpenClaw traces |

## Index of Fixes

### power-profile-switch

Installs a `udev` rule + systemd service that switches the CPU power
profile on AC/battery events.

```sh
cd power-profile-switch
sudo make install
```

### wlogout-fix

Fixes the HyDE logout menu (`SUPER + SHIFT + Q`) that failed to render
on HiDPI / scaled displays.

```sh
cp wlogout-fix/logoutlaunch.sh ~/.local/lib/hyde/logoutlaunch.sh
cp wlogout-fix/layout_1 wlogout-fix/style_1.css ~/.config/wlogout/
```

See `wlogout-fix/README.md` for full details.

## License

Private — for personal use.
