# ---------------------------------------------------------------------------
# TI CC33xx WiFi/BT -- ENABLED for imx95-phyflex-phyvip-1.
#
# Corrects an earlier assumption in this file. The phyVIP does not carry the
# NXP IW612 the Libra RDK has: schematic PV-05832-001-1645-0-004, sheet
# "WLAN/Bluetooth", designator U14 = BDE-BW3351UP1 -- a TI CC33xx module. That
# is exactly what this patch series drives, and it is why the series was
# written for the 8MP phyVIP / AM62 phyVERSO boards in the first place.
#
# The series applies cleanly to linux-phytec-imx 6.18.2 (verified with
# patch(1) against work-shared/.../kernel-source, all five patches, no fuzz).
# It adds drivers/net/wireless/ti/cc33xx and drivers/bluetooth/btti_* plus
# their Kconfig/Makefile hooks; nothing outside those two directories is
# touched, so other machines using this kernel recipe are unaffected -- and
# SRC_URI is guarded by the machine override regardless.
#
# 0001-mac80211-test-for-applying-changes-from-6.12-ti-kern.patch is NOT and
# must NOT be applied. Despite the name it is not a fix: it replaces 6.18's
# net/mac80211/mlme.c and wpa.c with the 6.12 TI versions (2027 deletions
# against 346 insertions), reverting the mac80211 core by six releases for the
# whole image. It stays in the layer only as a record of the original TI drop.
#
# Firmware comes from ti-cc33xx-firmware.bb in this layer, whose blobs are
# copied from PHYTEC's meta-phyverso-evcs (branch scarthgap) -- the same drop
# the AM62 phyVERSO EVCS uses for its CC3351, so both boards stay on one
# revision. linux-firmware would not have helped: it ships wl18xx, not cc33xx.
#
# Of the four files the driver names, only two are mandatory:
#   cc33xx_2nd_loader.bin, cc33xx_fw.bin  -- container_download_and_wait()
#       aborts the boot path if either is missing
#   cc33xx-conf.bin  -- optional; cc33xx_ini_bin_init() logs "falling back to
#       default config" and carries on. Shipped anyway.
#   cc33xx-nvs.bin   -- optional, MAC address only; not in the phyVERSO drop
#       either. Without it the MAC comes from EFUSE, else eth_random_addr().
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# HDMI via ITE IT6263 LVDS-to-HDMI bridge (imx95-phyflex-phyvip-1)
#
# Integrated from todo/meta-hdmi. That layer targeted the 6.12.34 NXP kernel,
# which is not COMPATIBLE_MACHINE for this board -- everything here is guarded
# by the machine override instead, so it applies to whatever kernel the machine
# selects (currently linux-phytec-imx 6.18.2-1.0.0-phy2).
#
# The CONFIG_MCX_JPEG fragment that came with meta-hdmi was deliberately NOT
# taken over: that Kconfig symbol does not exist in the 6.18.2 tree, so the
# fragment would be a silent no-op plus a kernel_configcheck warning.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# phyVIP carrier adaptation
#
# MACHINE imx95-phyflex-phyvip-1 gets its own base device tree,
# imx95-phyflex-phyvip.dts. It is not part of the kernel tree: it ships in this
# layer, #includes imx95-phyflex-libra-rdk.dts and corrects the carrier
# differences -- chiefly that the phyVIP has no I2C GPIO expanders. Left
# uncorrected, the two ti,tcal6416 at 0x21 never probe and fw_devlink parks
# their consumers, 4c300000.pcie among them: the root complex the Kinara Ara-2
# sits behind, which is why the accelerator did not show up in lspci at all.
#
# See the header of imx95-phyflex-phyvip.dts for the full analysis.
#
# The base DTB is listed in KERNEL_DEVICETREE in the machine conf, where it has
# to stay first so kernel-fitimage picks it as the FIT default configuration.
# Only the HDMI overlay is appended here.
# ---------------------------------------------------------------------------

# Search paths are harmless for other machines; only SRC_URI below is guarded.
FILESEXTRAPATHS:prepend := "${THISDIR}/linux-phytec-imx:${THISDIR}/linux-phytec-imx-hdmi:${THISDIR}/linux-phytec-imx-phyvip:"

SRC_URI:append:imx95-phyflex-phyvip-1 = " \
    file://0001-wifi-cc33xx-update-driver-to-match-cc33xx-SDK-1.0.2..patch \
    file://0002-wifi-cc33xx-Integrate-cc33xx-into-wireless-ti-folder.patch \
    file://0001-bluetooth-test-for-applying-changes-of-ti-6.12-kerne.patch \
    file://0001-drivers-cc33xx-forward-port-cc33xx-1.0.2.10-SDK-to-6.patch \
    file://0002-bluetooth-btti-add-Kconfig-and-Makefile-entries-for-.patch \
    file://cc33xx.cfg \
    file://it6263-hdmi.cfg \
    file://imx95-phyflex-phyvip-it6263-hdmi.dtso \
    file://0001-drm-imx95-ldb-relax-pixel-clock-tolerance.patch \
    file://imx95-phyflex-phyvip.dts \
"

KERNEL_DEVICETREE:append:imx95-phyflex-phyvip-1 = " freescale/imx95-phyflex-phyvip-it6263-hdmi.dtbo"

# Neither the board DTS nor the overlay is part of the kernel tree, so drop them
# in before the DTS Makefile is evaluated. No Makefile edit is needed:
# kernel-devicetree builds each KERNEL_DEVICETREE entry as an explicit make
# target, which scripts/Makefile.lib's %.dtb/%.dtso pattern rules resolve.
do_configure:prepend:imx95-phyflex-phyvip-1() {
    install -m 0644 ${UNPACKDIR}/imx95-phyflex-phyvip.dts \
        ${UNPACKDIR}/imx95-phyflex-phyvip-it6263-hdmi.dtso \
        ${S}/arch/${ARCH}/boot/dts/freescale/
}
