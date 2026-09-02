# Copyright (C) 2026 PHYTEC Messtechnik GmbH
# Author: Martin Podolszki <m.podolszki@phytec.de>

SUMMARY = "Firmware for the TI CC33xx radio module"
DESCRIPTION = "Boot loader and firmware containers for the TI CC33xx WiFi/BLE \
combo. On the phyVIP these drive the BDE-BW3351UP1 on the FPSC SDIO port."
SECTION = "kernel"

# Taken verbatim from PHYTEC's own meta-phyverso-evcs (branch scarthgap,
# recipes-bsp/firmware/ti-cc33xx-firmware), which ships the same blobs for the
# CC3351 on the phyVERSO EVCS. Same source, so the phyVIP and the AM62 board
# stay on one firmware revision. Adapted for walnascar: SRC_URI files unpack
# into UNPACKDIR, not WORKDIR, so the scarthgap recipe's "file://../COPYING.MIT"
# license path does not resolve here.

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# cc33xx-nvs.bin is deliberately absent -- it is not in the phyVERSO drop
# either. It carries nothing but a MAC address, and cc33xx_nvs_cb() handles it
# missing: the address then comes from the chip EFUSE, or, if that is blank,
# from eth_random_addr() with a warning in dmesg. Ship one later if a stable
# MAC is wanted.
SRC_URI = " \
    file://cc33xx_2nd_loader.bin \
    file://cc33xx_fw.bin \
    file://cc33xx-conf.bin \
    file://COPYING.MIT \
"

S = "${UNPACKDIR}"

inherit allarch

do_configure[noexec] = "1"
do_compile[noexec] = "1"

CC33XX_FW_DIR = "${nonarch_base_libdir}/firmware/ti-connectivity"

do_install() {
    install -d ${D}${CC33XX_FW_DIR}
    install -m 0644 ${S}/cc33xx_2nd_loader.bin ${D}${CC33XX_FW_DIR}/
    install -m 0644 ${S}/cc33xx_fw.bin ${D}${CC33XX_FW_DIR}/
    install -m 0644 ${S}/cc33xx-conf.bin ${D}${CC33XX_FW_DIR}/
}

FILES:${PN} = "${CC33XX_FW_DIR}"
