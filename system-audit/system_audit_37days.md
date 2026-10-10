# System Audit — past 37 days

**Host:** `abix` · **User:** `spix` · **OS:** Arch Linux (rolling)
**Window:** 2026-09-04 → 2026-10-10 · **Generated:** 2026-10-10
**Sources:** `pacman -Qe`, `/var/log/pacman.log`, `find /etc ~/.config -mtime -37`,
`~/.local/bin`, systemd unit lists.

ALPM activity in window: **236 installed · 79 removed · 428 upgraded** transactions.
Explicit package set at audit time: **158** (148 repo + 10 AUR).

## 1. Explicitly Installed Packages

Full restore lists: `packages-explicit.txt` (all), `packages-repo.txt` (pacman),
`packages-aur-explicit.txt` (yay/paru). `setup.sh` consumes them.

Notable arrivals / changes in window (from `pacman.log`):

| Area | Packages |
|---|---|
| Browsers / web | `chromium`, `firefox` + `firefoxpwa` (reinstalled), `brow6el` (replaces `browsh` stack), `carbonyl`, `chawan`, `links` variants (later removed) |
| Editors / IDE | `antigravity`, `beekeeper-studio`, `zed` (config below) |
| Android / RE | `android-studio`, `android-tools`, `scrcpy`, `radare2` + `capstone`, `zydis`/`zycore-c` |
| Media | `mpv`, `shotcut` + `mlt`/`frei0r-plugins`/`movit`, `kew`, `yt-dlp`, `gpu-screen-recorder`, `v4l2loopback-dkms` |
| Dev runtimes | `deno`, `nodejs-lts-jod` + `pnpm` (replaces `nodejs`+`corepack`), `jdk17-openjdk`, `rust` (later removed), `python-tqdm` (later removed) |
| Data / DB | `mongodb-bin` + `mongosh-bin`, `beekeeper-studio`, `pgadmin4*` (debug pkgs removed) |
| Desktop / Hyprland | `hyprpm`, `foot`, `konsole`, `kdeconnect` + KDE stack (`kcontacts`, `kpeople`, …), `qt6-*`, `xdg`/`wayland` scanners |
| System / net | `reflector`, `iperf3`, `speedtest-cli`, `strace`, `btop`, `ydotool`, `modemmanager`, `cups` (installed then removed), `linux-firmware-amd/ti`, `linux-headers`, `dkms` |
| Docs / office | `libreoffice-fresh`, `telegram-desktop` (reinstalled) |

Removed and not replaced: `go`, `firebase-tools-debug`, `mod_wsgi-debug`, `syft`,
`electron43` (→ `electron44`), `gtksourceview3`, assorted `*-debug` / `links` experiments.

## 2. Modified Dotfiles / Configs (`~/.config`)

Backed up under `dotfiles/.config/` (complete working sets, not just diffs).

| Path | What changed |
|---|---|
| `hypr/keybinds.lua`, `hyprland.lua` | Active keybind / core config edits (Oct 8–10) |
| `hypr/animations.conf`, `hyprlock.conf`, `hyprlock/theme.conf`, `themes/colors.conf` | Theming/animation tuning |
| `hypr/scripts/close-all-windows.sh` | New helper script |
| `waybar/*` | Smart-hide rework Sep 25 (`.bak`/`.orig` leftovers excluded), launcher script, theme/layout CSS |
| `fish/config.fish`, `user.fish`, `functions/gemma.fish`, `functions/cam.fish` | Shell customization + two new functions |
| `kitty/kitty.conf`, `theme.conf` | Terminal tuning |
| `zed/settings.json`, `keymap.json` | Editor config — **GitHub PAT sanitized to placeholder** (re-add manually) |
| `wlogout/style_1.css`, `style_2.css` | Logout menu styles (`style_2` is new) |
| `swaync/config.json`, `theme.css` | Notification center theming |
| `rofi/theme.rasi`, `mpv/mpv.conf` | Small tweaks |
| `systemd/user/*` | 10 custom user units/scripts (see §4) |
| `libinput-gestures.d/*.sh` | 7 gesture scripts |
| `opencode/commands/github.md`, `opencode/skills/github-push/` | New `/github` slash command + skill (created during this audit session) |
| `qt5ct/*`, `xsettingsd.conf`, `vim/colors/wallbash.vim`, `gtk-3.0/settings.ini`, `autostart/kdeconnect` | Theme/Qt integration |

Intentionally **excluded**: browser/app state (`zen`, `whatsapp-chromium`, `Postman`,
`Antigravity`, `Google`, … — caches, cookies, leveldb), `kdeconnect/` (**private keys**),
`~/.config/opencode/opencode.json` (**Copilot/MCP bearer token**), HyDE theme
wallpapers (`hyde/themes/*` — 218 files changed by theme switching, binaries),
`fish_variables` is included (only `$PATH`, no secrets).

## 3. Custom Scripts / Binaries (`~/.local/bin`)

Backed up under `dotfiles/.local/bin/` (pip shims excluded):

| Script | Purpose |
|---|---|
| `adb-auto-watch.fish` (Oct 3) | Auto-connect ADB over Wi-Fi (used by `adb-auto-connect.service`) |
| `airpods-volume-guard.sh` (Sep 5) | Clamps Bluetooth volume 100% → 60% (used by `airpods-volume-guard.service`) |

## 4. Environment / Service Changes

- **power-profile-switch** (this repo): udev rule + oneshot service installed Oct 10,
  enabled for boot (`systemctl enable`). See `../power-profile-switch/`.
- **`/etc/systemd/system/remote-login-cleanup.service`** (new, Oct 10): removes one-shot
  SDDM autologin before `sddm.service` (crash safety). Backed up under
  `dotfiles/etc/systemd/system/`; `setup.sh` prints the sudo install steps.
- **User services** (`systemd --user`): `gemma-llama-server` (local Gemma model on :8080),
  `adb-auto-connect`, `airpods-volume-guard`, `smart-hide`, `waybar-launcher`,
  `hyprpm-reload` (+watch script), `kdeconnect-headless`, `libinput-gestures` UWSM override.
- `redis.service` → `valkey.service` alias; TPM2/PCR units masked (Sep 25).
- No `.pacnew`/`.pacsave` files pending. `/etc/pacman.conf` touched Sep 3 (just
  outside window). `/etc/udev/rules.d/` holds only our power-profile rule.
- Active (uncommitted) project repos on disk, not backup targets here:
  `~/HyDE`, `~/GEMMA-TUI`, `~/portfolio`, `~/tookle-osint`, `~/apk-re-tools/*`.

## Restore

```bash
cd system-audit
./setup.sh                  # full: packages + dotfiles
./setup.sh --packages-only
./setup.sh --dotfiles-only
```

Existing dotfiles are moved aside (`*.audit-bak-<timestamp>`), never deleted.
Finish with the manual service steps printed by the script.
