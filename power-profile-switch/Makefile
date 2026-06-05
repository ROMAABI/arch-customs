PREFIX ?= /usr/local
UDEV_RULES_DIR ?= /etc/udev/rules.d
SYSTEMD_DIR ?= /etc/systemd/system

.PHONY: install uninstall verify

install:
	install -Dm755 power-profile-switch.sh $(DESTDIR)$(PREFIX)/bin/power-profile-switch.sh
	install -Dm644 power-profile-switch.service $(DESTDIR)$(SYSTEMD_DIR)/power-profile-switch.service
	install -Dm644 99-power-profile-switch.rules $(DESTDIR)$(UDEV_RULES_DIR)/99-power-profile-switch.rules
	systemctl daemon-reload
	udevadm control --reload-rules
	udevadm trigger --action=change --subsystem-match=power_supply
	@echo ""
	@echo "=== Installation complete ==="
	@echo "The service will activate on next AC adapter plug/unplug event."
	@echo "Run 'make verify' to test."

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/power-profile-switch.sh
	rm -f $(DESTDIR)$(SYSTEMD_DIR)/power-profile-switch.service
	rm -f $(DESTDIR)$(UDEV_RULES_DIR)/99-power-profile-switch.rules
	systemctl daemon-reload
	udevadm control --reload-rules
	@echo "=== Uninstallation complete ==="

verify:
	@echo "=== Verification ==="
	@echo ""
	@echo "1. Check script exists:"
	@test -x $(PREFIX)/bin/power-profile-switch.sh && echo "   [OK] Script installed" || echo "   [FAIL] Script not found"
	@echo ""
	@echo "2. Check service exists:"
	@test -f $(SYSTEMD_DIR)/power-profile-switch.service && echo "   [OK] Service installed" || echo "   [FAIL] Service not found"
	@echo ""
	@echo "3. Check udev rule exists:"
	@test -f $(UDEV_RULES_DIR)/99-power-profile-switch.rules && echo "   [OK] udev rule installed" || echo "   [FAIL] udev rule not found"
	@echo ""
	@echo "4. Verify udev rule syntax:"
	@udevadm verify $(UDEV_RULES_DIR)/99-power-profile-switch.rules 2>&1 || udevadm test /sys/class/power_supply/ADP1 2>&1 | head -20
	@echo ""
	@echo "5. Current power profile:"
	@powerprofilesctl get
	@echo ""
	@echo "6. Available profiles:"
	@powerprofilesctl list
	@echo ""
	@echo "7. Test: simulate AC plug event..."
	@echo "   Manually unplug/replug your AC adapter and check:"
	@echo "   journalctl -t power-profile-switch -n 10 --no-pager"
	@echo "   powerprofilesctl get"
