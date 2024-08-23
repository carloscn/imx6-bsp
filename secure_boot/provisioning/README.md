



sudo uuu -v SDP: boot -f u-boot_signed.imx.sdp  -nojump

sudo uuu -v SDP: write -f zImage_signed -addr 0x12000000

sudo uuu -v SDP: jump -f u-boot_signed.imx.sdp -ivt

mmc dev 1

setenv bootargs console=ttymxc0,115200 root=/dev/mmcblk3p2 rootwait rw consoleblank=0 rootfstype=ext4 dmfc=3 quiet

fatload mmc ${mmcdev}:${mmcpart} ${fdt_addr} ${board}.dtb

bootz ${loadaddr} - ${fdt_addr}

# Reference

* https://imxdev.gitlab.io/tutorial/Burning_eFuses_on_i.MX8_and_i.MX8x_families/
* https://imxdev.gitlab.io/tutorial/How_to_use_UUU_to_flash_the_iMX_boards/
