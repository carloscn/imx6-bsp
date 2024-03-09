include build.cfg
export $(shell sed 's/=.*//' build.cfg)

SHELL := /bin/bash
BOOT_SCR := boot.scr
UBOOT := u-boot/u-boot-dtb.imx
KERNEL_IMAGE := linux-imx/arch/arm/boot/zImage
DTB_IMAGE := linux-imx/arch/arm/boot/dts/imx6ull-14x14-evk.dtb

.PHONY: clean rootfs u-boot linux

prepare:
	git submodule init
	git submodule update --progress --depth=1

image: $(UBOOT) $(KERNEL_IMAGE) $(DTB_IMAGE) $(BOOT_SCR)

u-boot:
	-git clone git@github.com:u-boot/u-boot.git --depth=1
	cd u-boot && export CROSS_COMPILE=${CROSS_COMPILE} && \
		make mx6ull_14x14_evk_defconfig && make -j16
	ls -al u-boot/u-boot.bin
	@echo "[INFO] uboot build!"

bootscript:
	./u-boot/tools/mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d configs/boot.cmd boot.scr 6x_upgrade

linux:
	-git clone https://github.com/nxp-imx/linux-imx.git --depth=1
	cd linux-imx && \
		make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} imx_v7_defconfig && \
		make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -j16

$(KERNEL_IMAGE): linux

$(DTB_IMAGE): linux

$(BOOT_SCR): bootscript

$(UBOOT): u-boot

sd_all:
	@ls ${DISK}
	-sudo lsblk -ln -o MOUNTPOINT ${DISK} | grep -v '^$$' | xargs -r sudo umount
	sudo sfdisk ${UDISK} < configs/sd.layout --force
	sudo mkfs.fat -F32 -v -n "boot" ${UDISK}2
	sudo mkfs.ext4 -F -L "rootfs" ${UDISK}3
	sudo dd if=${UBOOT} of=${UDISK} bs=512 seek=2 && sync
	rm -rf temp_boot && mkdir -p temp_boot
	rm -rf temp_root && mkdir -p temp_root
	sudo mount ${UDISK}2 temp_boot
	sudo mount ${UDISK}3 temp_root
	sudo cp -rfv ${KERNEL_IMAGE} temp_boot/
	sudo cp -rfv ${DTB_IMAGE} temp_boot/
	sudo cp -rfv ${BOOT_SCR} temp_boot/
	sync
	sudo umount ${UDISK}2
	sudo umount ${UDISK}3
	echo "[INFO] done sd all!"

sd_boot:
	@ls ${DISK}
	sudo dd if=${UBOOT} of=${UDISK} bs=512 seek=2 && sync
	$(eval BOOT_PART=$(shell lsblk -no MOUNTPOINT ${UDISK} | grep -v '^$$' | head -n 1))
	@echo "Boot partition: $(BOOT_PART)"
	sudo cp -rfv ${KERNEL_IMAGE} ${BOOT_PART}/
	sudo cp -rfv ${DTB_IMAGE} ${BOOT_PART}/
	sudo cp -rfv ${BOOT_SCR} ${BOOT_PART}/
	sync
	sudo umount ${UDISK}2
	sudo umount ${UDISK}3

clean:
	rm -rf boot.scr
	sudo rm -rf temp_boot temp_root

distclean:
	rm -rf linux-imx u-boot
	make clean