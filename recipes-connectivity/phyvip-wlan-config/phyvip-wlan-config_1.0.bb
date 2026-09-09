# Copyright (C) 2026 PHYTEC Messtechnik GmbH
# Author: Martin Podolszki <m.podolszki@phytec.de>

SUMMARY = "WLAN client auto-connect for the phyVIP (TI CC33xx)"
DESCRIPTION = "Pins the wireless interface to wlan0, brings it up with DHCP \
via systemd-networkd, and starts wpa_supplicant against a network configured \
from PHYVIP_WLAN_SSID / PHYVIP_WLAN_PSK."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# ---------------------------------------------------------------------------
# Credentials come from build/conf/local.conf, never from this layer:
#
#   PHYVIP_WLAN_SSID = "MeinAP"
#   PHYVIP_WLAN_PSK  = "geheim"          # or a 64-char hex PSK
#
# local.conf is not part of the layer repository, so nothing secret ends up on
# GitHub. Without PHYVIP_WLAN_SSID the image bbappend does not install this
# package at all.
# ---------------------------------------------------------------------------
PHYVIP_WLAN_SSID ??= ""
PHYVIP_WLAN_PSK ??= ""

# The generated files depend on values that live outside any recipe file, so
# they have to be part of the task signature or a changed SSID would not
# trigger a rebuild.
do_install[vardeps] += "PHYVIP_WLAN_SSID PHYVIP_WLAN_PSK"

# Configuration is machine-specific.
PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI = ""

do_configure[noexec] = "1"
do_compile[noexec] = "1"

RDEPENDS:${PN} = "wpa-supplicant"

# Deliberately no "inherit systemd" / SYSTEMD_SERVICE here. The unit we want
# enabled, wpa_supplicant-nl80211@.service, is a template owned by the
# wpa-supplicant package; systemd.bbclass expects SYSTEMD_SERVICE to name a
# unit this recipe itself installs and fails QA otherwise. Instantiating a
# foreign template is done with the wants symlink below instead.

do_install() {
    # A wireless interface has no persistent kernel name, so systemd's default
    # policy would rename it to something MAC- or path-derived that is not
    # known at build time. Pin it, otherwise neither the .network file below
    # nor the wpa_supplicant service instance would match.
    install -d ${D}${systemd_unitdir}/network
    cat > ${D}${systemd_unitdir}/network/10-wlan.link <<EOT
[Match]
Type=wlan

[Link]
Name=wlan0
EOT

    cat > ${D}${systemd_unitdir}/network/25-wlan0.network <<EOT
[Match]
Name=wlan0

[Network]
DHCP=ipv4

[DHCPv4]
# Ask the DHCP server to register the hostname, so the board shows up under
# its own name in the lease table. The hostname itself is ${MACHINE}, set by
# base-files.
SendHostname=true
UseDomains=true
EOT

    install -d ${D}${sysconfdir}/wpa_supplicant
    {
        echo "ctrl_interface=/var/run/wpa_supplicant"
        echo "update_config=1"
        echo ""
        echo "network={"
        echo "    ssid=\"${PHYVIP_WLAN_SSID}\""
        # A 64-character hex string is already a derived PSK and must go in
        # unquoted; anything else is a passphrase and has to be quoted.
        if echo "${PHYVIP_WLAN_PSK}" | grep -Eq '^[0-9a-fA-F]{64}$'; then
            echo "    psk=${PHYVIP_WLAN_PSK}"
        else
            echo "    psk=\"${PHYVIP_WLAN_PSK}\""
        fi
        echo "}"
    } > ${D}${sysconfdir}/wpa_supplicant/wpa_supplicant-nl80211-wlan0.conf

    chmod 0600 ${D}${sysconfdir}/wpa_supplicant/wpa_supplicant-nl80211-wlan0.conf

    # Instantiate wpa_supplicant-nl80211@.service for wlan0. The template lives
    # in wpa-supplicant; %I resolves to "wlan0", which is why the config file
    # above is named wpa_supplicant-nl80211-wlan0.conf.
    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_unitdir}/system/wpa_supplicant-nl80211@.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/wpa_supplicant-nl80211@wlan0.service
}

FILES:${PN} = " \
    ${systemd_unitdir}/network/10-wlan.link \
    ${systemd_unitdir}/network/25-wlan0.network \
    ${sysconfdir}/wpa_supplicant \
    ${sysconfdir}/systemd/system/multi-user.target.wants/wpa_supplicant-nl80211@wlan0.service \
"

CONFFILES:${PN} = "${sysconfdir}/wpa_supplicant/wpa_supplicant-nl80211-wlan0.conf"
