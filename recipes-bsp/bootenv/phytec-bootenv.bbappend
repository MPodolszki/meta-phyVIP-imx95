# Overlay chain for the phyVIP carrier, replacing the LVDS panel overlay that
# meta-phytec ships as the default for imx95-phyflex-libra-rdk-2:
#
#   *-phyvip-carrier   fixes the DT for the phyVIP baseboard (no I2C GPIO
#                      expanders -- without this, PCIE1 and therefore the
#                      Kinara Ara-2 never probe)
#   *-it6263-hdmi      HDMI output via the ITE IT6263 LVDS-to-HDMI bridge
#
# U-Boot applies fit_overlay_conf entries in order, separated by '#'
# (see meta-ampliphy/recipes-bsp/u-boot/ampliphy-boot/mmc_boot_fit.cmd).
# The carrier fixup goes first so the HDMI overlay applies on top of it.
#
# Both kernel-side overlays are added in
# recipes-kernel/linux/linux-phytec-imx_%.bbappend.

do_deploy:append:imx95-phyflex-libra-rdk-2() {
    sed -i -e "s|^fit_overlay_conf=.*|fit_overlay_conf=conf-imx95-phyflex-libra-rdk-2-phyvip-carrier.dtbo#conf-imx95-phyflex-libra-rdk-2-it6263-hdmi.dtbo|" \
        ${DEPLOYDIR}/${BOOTENV_FILE}
}
