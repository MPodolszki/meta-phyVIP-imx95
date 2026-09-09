KINARA ?= "1"
HAILO ?= "0"

# PREFERRED_VERSION_tensorflow-lite = "2.19.0"
# PREFERRED_VERSION_tensorflow-lite-neutron-delegate = "2.19.0"
# PREFERRED_VERSION_litert = "1.2.0"
# PREFERRED_VERSION_litert-neutron-delegate = "1.2.0"

IMAGE_INSTALL:append = " \
    packagegroup-imx-ml \
    neutron \
    tensorflow-lite \
    litert \
    tensorflow-lite-neutron-delegate \
    litert-neutron-delegate \
    python3 \
    python3-pip \
    python3-venv \
    python3-numpy \
    python3-pandas \
    python3-opencv \
    python3-pycocotools \
    python3-netifaces \
    onnxruntime \
    onnxruntime-tests \
    git \
"

IMAGE_INSTALL:append = "${@bb.utils.contains('HAILO', '1', ' \
    hailo-firmware \
    libhailort \
    hailortcli \
    hailo-pci \
    libgsthailo \
    libgsthailotools \ 
    hailo-post-processes \
    pyhailort \
', '', d)}"

IMAGE_INSTALL:append = "${@bb.utils.contains('KINARA', '1', ' \
    kinara-uiodma \
    kinara-ddr-bringup \
    kinara-hwutils \
    uiodma-service \
    kinara-ara2-udev \
    kinara-ara2-service \
    kinara-ara2-runtime \
    kinara-ara2-tools \
    kinara-ara2-libs \
    kinara-ara2-wheels \
    kinara-ara2-uv \
    kinara-ara2-examples \
', '', d)}"

# kinara-hwutils liefert die statisch gelinkten Bring-up-Binaries
# (chip_info, program_pll, program_flash, active_enable) nach
# ${bindir}/kinara -- Gegenstuecke zum DDR-Bundle unter
# ${datadir}/rt-sdk-ara240_2.0.4/hw_utils/ddr_bringup.
#
# Bewusst NICHT installiert:
#   kinara-proxy      -- alter standalone proxy_aarch64; die Runtime startet
#                        proxy_ara240 aus kinara-ara2-runtime.
#   kinara-ara2-data  -- abgeloeste Sammel-Recipe, kollidiert mit
#                        -runtime/-libs/-tools/-examples/-udev/-service.

# TI CC33xx (BDE-BW3351UP1) firmware. Blobs and recipe taken from PHYTEC's
# meta-phyverso-evcs so phyVIP and the AM62 phyVERSO EVCS stay on one revision.
# Machine-guarded: no other machine using this image has the module.
IMAGE_INSTALL:append:imx95-phyflex-phyvip-1 = " ti-cc33xx-firmware"

# WLAN client auto-connect. Only pulled in when credentials are actually
# configured, so a build without them stays clean instead of shipping an empty
# wpa_supplicant.conf. Set in build/conf/local.conf, which is not part of any
# layer repository:
#
#   PHYVIP_WLAN_SSID = "MeinAP"
#   PHYVIP_WLAN_PSK  = "geheim"
IMAGE_INSTALL:append:imx95-phyflex-phyvip-1 = "${@' phyvip-wlan-config' if d.getVar('PHYVIP_WLAN_SSID') else ''}"

# Bluetooth on the CC33xx needs the BLE core switched on after btti_uart is
# listening (see recipes-connectivity/phyvip-bluetooth). Not tied to the WLAN
# credentials above: Bluetooth works without a configured network.
IMAGE_INSTALL:append:imx95-phyflex-phyvip-1 = " phyvip-bluetooth"

# Only exclude conflicting package when Kinara stack is enabled.
PACKAGE_EXCLUDE:append = "${@bb.utils.contains('KINARA', '1', ' gstreamer1.0-plugins-good-xingmux', '', d)}"