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

# ---------------------------------------------------------------------------
# DPU blit engine: "failed to get dmabuf" log flood (imx95-phyflex-phyvip-1)
#
# weston runs on the g2d renderer here (weston.ini: use-g2d=true, and the
# process has libg2d-dpu.so.2.4.0 mapped), so every repaint goes through the
# DPU blit ioctls -- and each one logged an unthrottled drm_err() per plane.
#
# Instrumenting the error path to print the descriptor and errno showed what
# is actually being handed in: fd 900, 438, 200, 168, all -EBADF, none of them
# open in the compositor. The values look like geometry rather than
# descriptors, so libg2d and the ioctl disagree about the layout of the buffer
# behind user_data. libg2d is a binary blob, so that half is not ours to fix,
# and it does no harm: the affected planes carry no data, the addresses
# programmed into the DPU come from the command list, and the picture is
# correct -- verified on the board.
#
# The patch therefore demotes both dma_buf_get() failures to drm_dbg() (still
# reachable via drm.debug, just not in everyone's dmesg), rejects fd <= 0 as
# "plane unused" -- 0 is a valid descriptor, so the old "fd < 0" guard let it
# through -- and stops adding the plane offset to an address that was never
# obtained.
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
    file://0001-drm-imx-dpu95-do-not-treat-fd-0-as-a-dmabuf-in-the-b.patch \
"

KERNEL_DEVICETREE:append:imx95-phyflex-phyvip-1 = " freescale/imx95-phyflex-phyvip-it6263-hdmi.dtbo"

# The base DTB must carry a /__symbols__ node or U-Boot cannot resolve the HDMI
# overlay at runtime -- measured 2026-09-03, the board stopped at:
#   failed on fdt_overlay_apply(): FDT_ERR_NOTFOUND
#   base fdt does not have a /__symbols__ node
#   make sure you've compiled with -@
#   Could not find a valid device tree / Boot failed (err=-14)
#
# imx95-phyflex-libra-rdk.dtb gets -@ for free because the DTS Makefile lists it
# as the base of several *-dtbs composite targets, and the kernel build adds the
# flag for an overlay base by itself. imx95-phyflex-phyvip.dts is not in that
# Makefile at all (see do_configure below), so nothing adds it here and the
# resulting DTB has no symbols. kernel-devicetree.bbclass exports
# KERNEL_DTC_FLAGS as DTC_FLAGS around the dtb targets; meta-phytec sets this
# only in linux-phytec_6.6.y-phy.bb, not in the imx recipe.
KERNEL_DTC_FLAGS:append:imx95-phyflex-phyvip-1 = " -@"

# Neither the board DTS nor the overlay is part of the kernel tree, so drop them
# in before the DTS Makefile is evaluated. No Makefile edit is needed:
# kernel-devicetree builds each KERNEL_DEVICETREE entry as an explicit make
# target, which scripts/Makefile.lib's %.dtb/%.dtso pattern rules resolve.
do_configure:prepend:imx95-phyflex-phyvip-1() {
    install -m 0644 ${UNPACKDIR}/imx95-phyflex-phyvip.dts \
        ${UNPACKDIR}/imx95-phyflex-phyvip-it6263-hdmi.dtso \
        ${S}/arch/${ARCH}/boot/dts/freescale/
}
