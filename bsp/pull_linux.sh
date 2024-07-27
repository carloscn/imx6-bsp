# !/bin/bash

source build.cfg

if [ -d "linux-imx" ]; then
    echo "[INFO] linux-imx directory already exists."
else
    echo "[INFO] linux-imx directory does not exist. Cloning repository."
    git clone ${LINUX_REPO} --depth=1 -b ${LINUX_BRANCH} && chmod -R 777 linux-imx
fi