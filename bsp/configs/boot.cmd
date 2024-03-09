setenv bootargs 'console=ttymxc0,115200 root=/dev/mmcblk0p3 rootwait rw'
setenv bootcmd 'mmc dev 0; fatload mmc 0:2 80800000 zImage; fatload mmc 0:2 83000000 imx6ull-14x14-evk.dtb;bootz 80800000 - 83000000;'
boot