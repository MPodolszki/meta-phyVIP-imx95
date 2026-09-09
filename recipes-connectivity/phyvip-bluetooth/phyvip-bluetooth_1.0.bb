# Copyright (C) 2026 PHYTEC Messtechnik GmbH
# Author: Martin Podolszki <m.podolszki@phytec.de>

SUMMARY = "Bluetooth bring-up for the phyVIP (TI CC33xx on lpuart5)"
DESCRIPTION = "Enables the CC33xx BLE core at boot through the WLAN driver's \
debugfs knob, sequenced after btti_uart is listening, so the one-shot wakeup \
event reaches the driver and hci0 appears."

# ---------------------------------------------------------------------------
# Why this exists (phyVIP, 2026-09-09):
#
# The CC33xx has one firmware for WLAN and BLE, loaded by the cc33xx WLAN
# driver. The BLE core stays off until the driver sends BLE_ENABLE, which it
# only does on a write to debugfs ble_enable -- core.enable_ble in
# cc33xx-conf.bin does not do it, and neither TI's cc33xx-target-scripts nor
# PHYTEC's phyVERSO overlay carry anything for it. Once enabled, the BT core
# sends its wakeup event on UART2 exactly once; btti_uart registers hci0 on
# that event and on nothing else. So the write has to happen after btti_uart
# reached STATE_HW_ON, and cannot be repeated without a cold start.
#
# The matching kernel side is 0003-bluetooth-btti_uart-tolerate-line-noise-
# before-the-w.patch in recipes-kernel: the wakeup arrives behind a few 0x00
# bytes of line noise on this board, which the stock matcher rejected.
#
# Independent of phyvip-wlan-config on purpose: that package is gated on WLAN
# credentials, Bluetooth is not.
# ---------------------------------------------------------------------------

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://cc33xx-ble-enable.sh \
    file://cc33xx-ble-enable.service \
"

# Nothing to unpack beyond the two files above; point S at them or do_unpack
# warns about a missing ${WORKDIR}/${BP}.
S = "${UNPACKDIR}"

# Only meaningful where the CC33xx sits.
COMPATIBLE_MACHINE = "imx95-phyflex-phyvip-1"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "cc33xx-ble-enable.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = "bluez5"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/cc33xx-ble-enable.sh ${D}${bindir}/
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/cc33xx-ble-enable.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    ${bindir}/cc33xx-ble-enable.sh \
    ${systemd_system_unitdir}/cc33xx-ble-enable.service \
"
