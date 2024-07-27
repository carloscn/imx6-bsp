setenv bootargs 'console=ttymxc0,115200 root=/dev/mmcblk0p3 rootwait rw'
setenv bootcmd 'mmc dev 0; fatload mmc 0:2 ${loadaddr} zImage_signed; fatload mmc 0:2 ${fdt_addr} imx6ull-14x14-evk.dtb;bootz ${loadaddr} - ${fdt_addr};'
boot