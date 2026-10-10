#!/bin/bash
# Power Profile Switch - Automated Installer
# Run with: sudo ./install.sh

set -euo pipefail

echo "=== Power Profile Switch Installer ==="
echo ""

# --- Prerequisites check ---
echo "[1/6] Checking prerequisites..."
PACKAGES_MISSING=""
for cmd in powerprofilesctl systemctl udevadm; do
    if ! command -v "$cmd" &>/dev/null; then
        PACKAGES_MISSING="$PACKAGES_MISSING $cmd"
    fi
done

if [ -n "$PACKAGES_MISSING" ]; then
    echo "ERROR: Missing required commands:$PACKAGES_MISSING"
    echo "Install: sudo pacman -S power-profiles-daemon systemd udev"
    exit 1
fi

# Check if power-profiles-daemon is running
if ! systemctl is-active --quiet power-profiles-daemon; then
    echo "WARNING: power-profiles-daemon is not running. Enabling..."
    systemctl enable --now power-profiles-daemon || {
        echo "ERROR: Failed to start power-profiles-daemon"
        exit 1
    }
fi

# Check for AC adapter device
ADAPTER=$(ls /sys/class/power_supply/ | grep -i -E 'AC|ADP' | head -1)
if [ -z "$ADAPTER" ]; then
    echo "ERROR: No AC adapter device found in /sys/class/power_supply/"
    echo "Available power supplies:"
    ls /sys/class/power_supply/
    exit 1
fi
echo "   Detected AC adapter: $ADAPTER"

echo "   [OK] All prerequisites satisfied"
echo ""

# --- Disable potentially conflicting built-in battery-aware mode ---
echo "[2/6] Disabling built-in battery-aware mode (avoids conflicts)..."
if powerprofilesctl query-battery-aware 2>/dev/null | grep -q "True"; then
    powerprofilesctl configure-battery-aware --disable
    echo "   Disabled battery-aware mode"
else
    echo "   Already disabled"
fi
echo ""

# --- Install script ---
echo "[3/6] Installing switch script..."
install -Dm755 power-profile-switch.sh /usr/local/bin/power-profile-switch.sh
echo "   Installed: /usr/local/bin/power-profile-switch.sh"
echo ""

# --- Install systemd service ---
echo "[4/6] Installing systemd service..."
install -Dm644 power-profile-switch.service /etc/systemd/system/power-profile-switch.service
systemctl daemon-reload
echo "   Installed: /etc/systemd/system/power-profile-switch.service"
echo ""

# --- Install udev rule ---
echo "[5/6] Installing udev rule..."
# Replace adapter name in udev rule if different from ADP1
if [ "$ADAPTER" != "ADP1" ]; then
    sed "s/KERNEL==\"ADP1\"/KERNEL==\"$ADAPTER\"/" 99-power-profile-switch.rules > /etc/udev/rules.d/99-power-profile-switch.rules
    echo "   (adapted KERNEL match to \"$ADAPTER\")"
else
    install -Dm644 99-power-profile-switch.rules /etc/udev/rules.d/99-power-profile-switch.rules
fi
udevadm control --reload-rules
echo "   Installed: /etc/udev/rules.d/99-power-profile-switch.rules"
echo ""

# --- Test and verify ---
echo "[6/6] Running verification..."
echo ""
echo "   Current power profile: $(powerprofilesctl get)"
echo "   Available profiles:"
    powerprofilesctl list | grep "^\s" | head -5
echo ""
echo "   Testing udev rule..."
udevadm test /sys/class/power_supply/"$ADAPTER" 2>&1 | grep -E 'power-profile|systemd' | head -5 || true
echo ""

echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "  1. Unplug your AC adapter -> check profile switches to power-saver"
echo "  2. Plug AC adapter back in -> check profile switches to performance"
echo ""
echo "  Monitor with:  journalctl -t power-profile-switch -f"
echo "  Verify with:   powerprofilesctl get"
echo ""
echo "  To test manually (ignoring udev):"
echo "    sudo /usr/local/bin/power-profile-switch.sh"
