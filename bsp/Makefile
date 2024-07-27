include build.cfg
export $(shell sed 's/=.*//' build.cfg)

SHELL := /bin/bash
BOOT_SCR := boot.scr
UBOOT := u-boot/u-boot-dtb.imx
KERNEL_IMAGE := linux-imx/arch/arm/boot/zImage
DTB_IMAGE := linux-imx/arch/arm/boot/dts/imx6ull-14x14-evk.dtb
QEMU_DIR=/opt/qemu/bin
QEMU_BIN ?= $(QEMU_DIR)/qemu-system-arm

.PHONY: clean rootfs u-boot linux

prepare:
	git submodule init
	git submodule update --progress --depth=1

image: $(UBOOT) $(KERNEL_IMAGE) $(DTB_IMAGE) $(BOOT_SCR)

u-boot: $(UBOOT)

CONFIG_NAME=$(notdir $(UBOOT_USER_CONFIG))
CONFIG_TARGET=$(basename $(CONFIG_NAME))

$(UBOOT):
	bash pull_uboot.sh
	cd u-boot && export CROSS_COMPILE=${CROSS_COMPILE} && \
		make mx6ull_14x14_evk_emmc_defconfig
ifneq ($(UBOOT_USER_CONFIG),)
	cd u-boot && export CROSS_COMPILE=${CROSS_COMPILE} && \
		cp -rfv $(UBOOT_USER_CONFIG) ./configs/ && \
		make $(CONFIG_TARGET)
endif
	cd u-boot && make -j16
	ls -al u-boot/u-boot-dtb.imx
	@echo "[INFO] uboot build!"

bootscript:
	./u-boot/tools/mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d configs/boot.cmd boot.scr 6x_upgrade

linux: $(KERNEL_IMAGE) $(DTB_IMAGE)

$(DTB_IMAGE):
$(KERNEL_IMAGE):
	bash pull_linux.sh
	cd linux-imx && \
		make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} imx_v7_defconfig && \
		make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -j16

virutal-disk: disk.img

uimage:
	./u-boot/tools/mkimage -f configs/imx6ull_fit_image.its image.ub
	./u-boot/tools/mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d configs/boot_fit.cmd boot.scr 6x_upgrade

disk.img: $(KERNEL_IMAGE) $(DTB_IMAGE)
	$(QEMU_DIR)/qemu-img create -f raw t_disk.img 1G
	parted t_disk.img mklabel msdos
	parted t_disk.img mkpart primary ext4 1M 100%
	sudo losetup /dev/loop51 t_disk.img
	sudo kpartx -av /dev/loop51
	sudo mkfs.ext4 /dev/mapper/loop51p1
	sudo dd if=u-boot/u-boot-dtb.imx of=t_disk.img bs=512 seek=2 conv=notrunc
	sudo mount /dev/mapper/loop51p1 /mnt
	sudo cp -rfv linux-imx/arch/arm/boot/dts/nxp/imx/imx6ul-14x14-evk.dtb /mnt/
	sudo cp -rfv linux-imx/arch/arm/boot/zImage /mnt/
	sudo umount /mnt
	sudo kpartx -d /dev/loop51
	sudo losetup -d /dev/loop51
	mv t_disk.img disk.img

qemuk: $(KERNEL_IMAGE) disk.img
	$(QEMU_BIN) -M mcimx6ul-evk -m 1024M -nographic \
		-kernel linux-imx/arch/arm/boot/zImage \
		-dtb linux-imx/arch/arm/boot/dts/nxp/imx/imx6ul-14x14-evk.dtb \
		-drive file=disk.img,format=raw,id=mysdcard -device sd-card,drive=mysdcard \
		-append "console=ttymxc0 loglevel=8 earlycon earlyprintk rootfstype=ext4 root=/dev/mmcblk1 rw rootwait init=/sbin/init"

qemuu:
	$(QEMU_BIN) -M mcimx6ul-evk -m 1G -nographic \
		-drive file=disk.img,format=raw,id=mycard \
		-device sd-card,drive=mycard,bus=sd-bus \
		-no-reboot

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
	rm -rf *.img image.ub
	rm -rf $(UBOOT) $(KERNEL_IMAGE) $(DTB_IMAGE) $(BOOT_SCR)

distclean:
	rm -rf linux-imx u-boot
	make clean
