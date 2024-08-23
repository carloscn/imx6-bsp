# !/bin/bash

KERNEL_LOAD_ADDR=0x12000000
UBOOT_SDP_SIGNED=u-boot_signed.imx.sdp
UBOOT=u-boot.imx
KERNEL_SIGNED=zImage_signed

sudo uuu -v SDP: boot -f ${UBOOT}  -nojump

sudo uuu -v SDP: write -f ${zImage_signed} -addr ${KERNEL_LOAD_ADDR}

sudo uuu -v SDP: jump -f ${UBOOT} -ivt

sudo uuu -v SDP: boot -f  ${UBOOT} \
                +FB: ucmd fuse prog -y 3 0 0xAEF1AB3A \
                +FB: ucmd fuse prog -y 3 1 0x693706CC \
                +FB: ucmd fuse prog -y 3 2 0x4B4F0A16 \
                +FB: ucmd fuse prog -y 3 3 0xCF17161E \
                +FB: ucmd fuse prog -y 3 4 0xB3F19592 \
                +FB: ucmd fuse prog -y 3 5 0xE3AD7660 \
                +FB: ucmd fuse prog -y 3 6 0x8E55CC4F \
                +FB: ucmd fuse prog -y 3 7 0x21C19E4B \
                 FB: ucmd setenv bootargs 'console=ttymxc0,115200 root=/dev/mmcblk0p3 rootwait rw' \
                 FB: ucmd setenv bootcmd 'mmc dev 0; fatload mmc 0:2 ${loadaddr} zImage_signed; fatload mmc 0:2 ${fdt_addr} imx6ull-14x14-evk.dtb;bootz ${loadaddr} - ${fdt_addr};'

