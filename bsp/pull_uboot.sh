# !/bin/bash

source build.cfg

if [ -d "u-boot" ]; then
    echo "[INFO] u-boot directory already exists."
else
    echo "[INFO] u-boot directory does not exist. Cloning repository."
    git clone ${UBOOT_REPO} u-boot --depth=1 -b ${UBOOT_BRANCH} && chmod -R 777 u-boot
fi