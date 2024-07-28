# !/bin/bash

source build.cfg

if [ -d "buildroot" ]; then
    echo "[INFO] buildroot directory already exists."
else
    echo "[INFO] buildroot directory does not exist. Cloning repository."
    git clone ${BUILDROOT_REPO} --depth=1 -b ${BUILDROOT_BRANCH} && chmod -R a+rw buildroot
fi