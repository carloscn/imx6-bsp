setenv bootargs 'console=ttymxc0,115200 root=/dev/mmcblk0p3 rootwait rw'
setenv bootcmd 'mmc dev 0; fatload mmc 0:2 82100000 image.ub; bootm 82100000;'
boot