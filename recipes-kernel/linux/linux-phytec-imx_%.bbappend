# ---------------------------------------------------------------------------
# TI CC33xx WiFi/BT -- DEFERRED, intentionally not applied.
#
# The patch series (and cc33xx.cfg) is still in recipes-kernel/linux/
# linux-phytec-imx/ and forward-ported to 6.18.y, but it is not wired into
# SRC_URI: WLAN is postponed on the phyVIP-imx95, and this board carries an
# NXP IW612 (MACHINE_FEATURES "nxpiw612-sdio"), not a TI CC33xx -- there is no
# cc33xx node in any imx95 device tree. The series originates from the 8MP
# phyVIP / AM62 phyVERSO work; the imx8mp-phyflex-phyvip*.dts* and
# k3-am625-phyverso-evcs-cc3351.dtso that used to sit next to these patches
# were copy leftovers from those boards and have been removed.
#
# To re-enable, restore the block below and guard it with the override of the
# machine that actually has the CC33xx fitted -- it must NOT be a bare
# SRC_URI:append, which would hit every machine using this kernel recipe:
#
#   FILESEXTRAPATHS:prepend := "${THISDIR}/linux-phytec-imx:"
#   SRC_URI:append:<machine> = " \
#       file://0001-wifi-cc33xx-update-driver-to-match-cc33xx-SDK-1.0.2..patch \
#       file://0002-wifi-cc33xx-Integrate-cc33xx-into-wireless-ti-folder.patch \
#       file://0001-bluetooth-test-for-applying-changes-of-ti-6.12-kerne.patch \
#       file://0001-drivers-cc33xx-forward-port-cc33xx-1.0.2.10-SDK-to-6.patch \
#       file://0002-bluetooth-btti-add-Kconfig-and-Makefile-entries-for-.patch \
#       file://cc33xx.cfg \
#   "
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
FILESEXTRAPATHS:prepend := "${THISDIR}/linux-phytec-imx-hdmi:${THISDIR}/linux-phytec-imx-phyvip:"

SRC_URI:append:imx95-phyflex-phyvip-1 = " \
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
