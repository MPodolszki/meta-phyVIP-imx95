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
# HDMI via ITE IT6263 LVDS-to-HDMI bridge (imx95-phyflex-libra-rdk-2 / phyVIP)
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
# MACHINE is imx95-phyflex-libra-rdk-2 and the base DT it boots describes the
# Libra RDK carrier, but the hardware is the phyVIP carrier
# (PV-05832-001-1645-0-004). The phyVIP has no I2C GPIO expanders, so the two
# ti,tcal6416 nodes at 0x21 never probe and fw_devlink parks their consumers --
# including 4c300000.pcie, which is the PCIe root complex the Kinara Ara-2 sits
# behind -- in permanent deferred probe.
#
# See the header of imx95-phyflex-libra-rdk-2-phyvip-carrier.dtso for the full
# analysis. Long term this should become a proper phyVIP MACHINE with its own
# device tree instead of an overlay on top of a foreign carrier's DT.
# ---------------------------------------------------------------------------

# Search paths are harmless for other machines; only SRC_URI below is guarded.
FILESEXTRAPATHS:prepend := "${THISDIR}/linux-phytec-imx-hdmi:${THISDIR}/linux-phytec-imx-phyvip:"

SRC_URI:append:imx95-phyflex-libra-rdk-2 = " \
    file://it6263-hdmi.cfg \
    file://imx95-phyflex-libra-rdk-2-it6263-hdmi.dtso \
    file://0001-drm-imx95-ldb-relax-pixel-clock-tolerance.patch \
    file://imx95-phyflex-libra-rdk-2-phyvip-carrier.dtso \
"

KERNEL_DEVICETREE:append:imx95-phyflex-libra-rdk-2 = " \
    freescale/imx95-phyflex-libra-rdk-2-it6263-hdmi.dtbo \
    freescale/imx95-phyflex-libra-rdk-2-phyvip-carrier.dtbo \
"

# The overlays are not part of the kernel tree, so drop them in before the DTS
# Makefile is evaluated. kernel-devicetree builds them via KERNEL_DEVICETREE.
do_configure:prepend:imx95-phyflex-libra-rdk-2() {
    install -m 0644 ${UNPACKDIR}/imx95-phyflex-libra-rdk-2-it6263-hdmi.dtso \
        ${UNPACKDIR}/imx95-phyflex-libra-rdk-2-phyvip-carrier.dtso \
        ${S}/arch/${ARCH}/boot/dts/freescale/
}
