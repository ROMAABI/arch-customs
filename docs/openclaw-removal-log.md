# OpenClaw Removal — Session README

**Date**: 2026-05-28  
**Session ID**: `ses_19531b0beffezDs3dnY2uzbgeD`  
**Host**: `abix` — Linux, user `spix`

---

## Installation Method Detected

**npm global install** with custom prefix `~/.npm-global`

The `$HOME/.npm-global/bin` directory was added to `PATH` in `~/.bashrc` (line 38). This PATH entry was preserved — it is shared infrastructure used by other npm global tools.

---

## Inventory of All Traces Found & Removed

| # | Artifact | Location | Size | Action |
|---|----------|----------|------|--------|
| 1 | **Running process** | PID 654 — `node .../openclaw/dist/index.js gateway --port 8080` | 678 MB RSS | `systemctl --user stop` |
| 2 | **Systemd user service** (enabled, active) | `~/.config/systemd/user/openclaw-gateway.service` | — | Disabled + file deleted |
| 3 | **Systemd unit copies** | `.servic` (typo), `.bak` | — | Deleted |
| 4 | **npm global package** | `~/.npm-global/lib/node_modules/openclaw/` | **774 MB** (372 sub-packages) | `npm -g uninstall openclaw` |
| 5 | **Binary symlink** | `~/.npm-global/bin/openclaw → ../lib/node_modules/openclaw/openclaw.mjs` | — | Gone after npm uninstall |
| 6 | **Config + credentials + workspace** | `~/.openclaw/` | **15 MB** (2,737 files) | `rm -rf` |
| 7 | **Shell completions** | Inside `~/.openclaw/completions/` (bash, zsh, fish, ps1) | — | Removed with parent dir |
| 8 | **Temp runtime files** | `/tmp/openclaw/` (log), `/tmp/jiti/*openclaw*` (14 cached modules) | ~123 KB | Deleted |
| 9 | **npm cache** | 12 entries for `@openclaw/*` packages | — | `npm cache clean --force` |
| 10 | **Systemd daemon state** | Cached unit references | — | `systemctl --user daemon-reload` + `reset-failed` |

---

## Traces Preserved (No Action Taken)

| Location | Reason |
|----------|--------|
| `~/.npm-global/bin` in `~/.bashrc` PATH | Shared PATH entry — removing it would break other npm global tools |
| `~/.npm-global/lib/node_modules/nemoclaw/node_modules/openclaw/` | This is a **nested dependency** of `nemoclaw`, a different package. Removing it would break `nemoclaw` |

---

## Commands Executed (in order)

```bash
# 1. Stop + disable the running service
systemctl --user stop openclaw-gateway.service
systemctl --user disable openclaw-gateway.service

# 2. Remove systemd unit files
rm ~/.config/systemd/user/openclaw-gateway.service \
   ~/.config/systemd/user/openclaw-gateway.servic \
   ~/.config/systemd/user/openclaw-gateway.service.bak

# 3. Uninstall npm global package
npm -g uninstall openclaw

# 4. Remove config/data directory
rm -rf ~/.openclaw/

# 5. Clean temp files
rm -rf /tmp/openclaw/
rm -f /tmp/jiti/*openclaw*

# 6. Clean npm cache
npm cache clean --force

# 7. Reload systemd
systemctl --user daemon-reload
systemctl --user reset-failed
```

---

## Verification Results

| Check | Result |
|-------|--------|
| `which openclaw` | Not found |
| `ps aux \| grep openclaw` | No process |
| `systemctl --user list-units \| grep openclaw` | No units |
| `find ~/.config/systemd -name '*openclaw*'` | No files |
| `npm list -g --depth=0 \| grep openclaw` | Not found |
| `ls ~/.openclaw` | Directory gone |
| `ls /tmp/openclaw` | Directory gone |
| `npm cache ls \| grep openclaw` | No cache entries |

**Status: CLEAN** — no standalone OpenClaw traces remain on the system.
