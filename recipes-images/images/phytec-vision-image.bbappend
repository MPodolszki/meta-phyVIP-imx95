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

# Only exclude conflicting package when Kinara stack is enabled.
PACKAGE_EXCLUDE:append = "${@bb.utils.contains('KINARA', '1', ' gstreamer1.0-plugins-good-xingmux', '', d)}"