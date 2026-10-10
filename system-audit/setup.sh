#!/bin/bash
# arch-customs/system-audit/setup.sh — one-click restore after an OS reinstall.
# 1. Installs repo packages (pacman) + AUR packages (yay/paru).
# 2. Restores dotfiles from dotfiles/ into $HOME (existing files are backed
#    up with an .audit-bak-<date> suffix, never overwritten blindly).
# 3. Prints manual steps for system-level units (need sudo) and user services.
#
# Usage: ./setup.sh [--packages-only | --dotfiles-only]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX=".audit-bak-$(date +%Y%m%d-%H%M%S)"
PACKAGES_ONLY=false
DOTFILES_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --packages-only) PACKAGES_ONLY=true ;;
        --dotfiles-only) DOTFILES_ONLY=true ;;
        -h|--help)
            echo "Usage: $0 [--packages-only | --dotfiles-only]"
            exit 0 ;;
        *) echo "Unknown arg: $arg" >&2; exit 1 ;;
    esac
done

command -v pacman &>/dev/null || { echo "ERROR: pacman not found (not Arch?)" >&2; exit 1; }

# --- 1. Packages -----------------------------------------------------------
if ! $DOTFILES_ONLY; then
    echo "==> Installing repo packages (pacman)..."
    sudo pacman -S --needed --noconfirm - < "$SCRIPT_DIR/packages-repo.txt"

    if [ -s "$SCRIPT_DIR/packages-aur-explicit.txt" ]; then
        HELPER=""
        command -v yay &>/dev/null && HELPER="yay"
        [ -z "$HELPER" ] && command -v paru &>/dev/null && HELPER="paru"
        if [ -n "$HELPER" ]; then
            echo "==> Installing AUR packages ($HELPER)..."
            "$HELPER" -S --needed --noconfirm - < "$SCRIPT_DIR/packages-aur-explicit.txt"
        else
            echo "WARNING: no AUR helper (yay/paru) found, skipping AUR list:"
            cat "$SCRIPT_DIR/packages-aur-explicit.txt"
            echo "Install yay, then re-run: yay -S --needed - < packages-aur-explicit.txt"
        fi
    fi
fi

# --- 2. Dotfiles -----------------------------------------------------------
if ! $PACKAGES_ONLY; then
    echo "==> Restoring dotfiles (backups get $BACKUP_SUFFIX)..."
    for src in "$SCRIPT_DIR"/dotfiles/.*; do
        base="$(basename "$src")"
        [[ "$base" == "." || "$base" == ".." ]] && continue
        dest="$HOME/$base"
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "    backing up $dest -> ${dest}${BACKUP_SUFFIX}"
            mv "$dest" "${dest}${BACKUP_SUFFIX}"
        fi
        [ -L "$dest" ] && rm "$dest"
        echo "    restoring $base"
        cp -a "$src" "$dest"
    done
    chmod +x "$HOME/.local/bin/"*.sh "$HOME/.local/bin/"*.fish 2>/dev/null || true
    echo "==> Reloading user systemd units..."
    systemctl --user daemon-reload || true
fi

# --- 3. Manual steps -------------------------------------------------------
cat <<'EOF'

==> Manual steps (run once, review first):
  # System unit (needs sudo):
  sudo install -Dm644 dotfiles/etc/systemd/system/remote-login-cleanup.service \
      /etc/systemd/system/remote-login-cleanup.service
  sudo systemctl daemon-reload
  sudo systemctl enable remote-login-cleanup.service

  # User services (enable only the ones you want):
  systemctl --enable --now adb-auto-connect.service airpods-volume-guard.service
  systemctl --enable --now smart-hide.service waybar-launcher.service
  systemctl --enable --now kdeconnect-headless.service gemma-llama-server.service

  # Power profile switcher (see ../power-profile-switch/):
  (cd ../power-profile-switch && sudo bash ./install.sh) && \
      sudo systemctl enable power-profile-switch.service

  # Zed: dotfiles/.config/zed/settings.json has a placeholder where the
  # GitHub token was — paste your token back before launching Zed.
EOF

echo ""
echo "Done."
