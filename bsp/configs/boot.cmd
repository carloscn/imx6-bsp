part uuid mmc 0:2 uuid
setenv bootargs console=ttymxc0,115200 root=PARTUUID=${uuid} rootfstype=ext4 fsck.repair=yes rootwait rw
fatload mmc 0:2 80800000 zImage
fatload mmc 0:2 83000000 imx6ull-14x14-evk-emmc.dtb
bootz 80800000 - 83000000