#!/bin/bash

cp -rfv ../../bsp/linux-imx/arch/arm/boot/zImage ./ && \
cp -rfv ../../bsp/u-boot/u-boot-dtb.imx ./u-boot.imx && \
cp -rfv ../../bsp/u-boot/u-boot-dtb.imx.log ./ || echo "[INFO] copy failed!"
