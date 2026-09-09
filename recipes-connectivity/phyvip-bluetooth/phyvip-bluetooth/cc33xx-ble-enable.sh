#!/bin/sh
# Switch on the BLE core of the TI CC33xx through the WLAN side of the chip.
#
# The cc33xx WLAN driver leaves BLE off at start (ble_enable = 0) and nothing
# in the TI SDK turns it on; core.enable_ble in cc33xx-conf.bin is not enough.
# Writing 1 to the debugfs knob sends the BLE_ENABLE firmware command, after
# which the BT core sends its wakeup event on the UART exactly ONCE. btti_uart
# registers its HCI device only on that event, so it must already be listening
# (STATE_HW_ON) when we write -- otherwise there is no hci until the next cold
# start. Measured on the phyVIP, 2026-09-09.
F=/sys/kernel/debug/ieee80211/phy0/cc33xx/ble_enable

for i in $(seq 1 60); do [ -e "$F" ] && break; sleep 1; done
[ -e "$F" ] || { echo "cc33xx debugfs entry not present" >&2; exit 1; }
[ "$(cat "$F")" = "1" ] && exit 0

for i in $(seq 1 30); do dmesg | grep -q "btti.*STATE_HW_ON" && break; sleep 1; done
sleep 1
echo 1 > "$F"
