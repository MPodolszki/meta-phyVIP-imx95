# Overlay selection for the phyVIP.
#
# The carrier itself is described by the base device tree
# (freescale/imx95-phyflex-phyvip.dtb, see
# recipes-kernel/linux/linux-phytec-imx_%.bbappend), so the only overlay left to
# select at boot is HDMI output via the ITE IT6263 LVDS-to-HDMI bridge.
#
# imx95-phyflex-phyvip-1 keeps imx95-phyflex-libra-rdk-2 in MACHINEOVERRIDES,
# which means meta-phytec's overlays.txt for the RDK -- selecting the RDK LVDS
# panel -- is still on FILESPATH. Ours sits in a higher-priority machine
# directory and wins outright.
#
# Multiple overlays would be separated by '#', see
# meta-ampliphy/recipes-bsp/u-boot/ampliphy-boot/mmc_boot_fit.cmd.

FILESEXTRAPATHS:prepend := "${THISDIR}/phytec-bootenv:"
