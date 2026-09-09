# Copyright (C) 2026 PHYTEC Messtechnik GmbH
# Author: Martin Podolszki <m.podolszki@phytec.de>

SUMMARY = "Firmware for the TI CC33xx radio module"
DESCRIPTION = "Boot loader and firmware containers for the TI CC33xx WiFi/BLE \
combo. On the phyVIP these drive the BDE-BW3351UP1 on the FPSC SDIO port."
SECTION = "kernel"

# Blobs from the TI CC33xx Linux MPU SDK 1.0.2.10, file
# cc33xx/cc33xx_rootfs/lib/firmware/ti-connectivity/ of
#   https://dr-download.ti.com/software-development/driver-or-library/\
#   MD-UoRUAALCjn/1.0.2.10/cc33xx_linux_package_1_0_2_10.run
#
# 1.0.2.10 is the SDK that TI pairs with the 6.18.y kernel port we carry, see
# the kernel table in
#   https://github.com/TexasInstruments-Sandbox/cc33xx-linux-mpu-ports
# whose 6.18.y/0001-drivers-cc33xx-forward-port-... patch is exactly the one in
# recipes-kernel/linux/linux-phytec-imx/.
#
# These blobs deliberately do NOT come from ti-linux-firmware (nor from
# PHYTEC's meta-phyverso-evcs, which just mirrors it). Every branch of
# ti-linux-firmware still ships FW 1.7.0.120 with a 1353-byte cc33xx-conf.bin;
# our driver's struct cc33xx_conf_file is 1282 bytes and its conf.h declares
# CC33XX_CONF_FW_{MAJOR,MINOR,API,BUILD}_VERSION = 1/7/0/0x13C. Measured on the
# phyVIP 2026-09-03, the 1.7.0.120 pair gets as far as running the FW and then
# dies:
#   cc33xx: ERROR ...conf.bin configuration binary size is wrong, expected 1282 got 1353
#   cc33xx: ERROR FW is stuck, triggering recovery
#   cc33xx: WARNING download INI params to FW command sending failed: -5
# The SDK 1.0.2.10 conf.bin is 1282 bytes and its header carries exactly those
# four version words; cc33xx_fw.bin reports cc3xxx_rev_1.7.0.323.

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# cc33xx-nvs.bin is deliberately absent -- the SDK 1.0.2.10 rootfs does not
# ship one either. It carries nothing but a MAC address, and cc33xx_nvs_cb() handles it
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
