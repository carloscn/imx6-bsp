.PHONY: all clean

all:
	@echo "[INFO] Changing to bsp directory and pulling u-boot."
	cd bsp && bash pull_uboot.sh

	@echo "[INFO] Changing to bsp directory and pulling linux."
	cd bsp && bash pull_linux.sh

	@echo "[INFO] Checking for Docker image with tag 'imx6_yoctocontainer'."
	bash build_docker.sh

	@echo "[INFO] Running Docker container."
	bash run_docker.sh

	@echo "[INFO] Copying"
	@cp -rfv secure_boot/sign_image/zImage_signed .
	@cp -rfv secure_boot/sign_image/u-boot_signed.imx .
	@md5sum zImage_signed u-boot_signed.imx
	@echo "[INFO] $ dd if=u-boot_signed.imx of=/dev/sdx bs=1K seek=1 && sync"
	@echo "[INFO] $ cp -rfv zImage_signed /media/${USER}/boot/"

uuu:
	@sudo apt install libusb-1.0-0-dev libbz2-dev libzstd-dev pkg-config cmake libssl-dev g++ zlib1g-dev libtinyxml2-dev
	@git submodule init
	@git submodule update
	@cd mfgtools && cmake -S . -B build
	@cd mfgtools && cmake --build build --target all
	@cd mfgtools/build && sudo make install
	@uuu -h

clean:
	rm -rf zImage_signed u-boot_signed.imx
	make clean -C bsp
	make clean -C secure_boot/sign_image

distclean: clean
	make distclean -C bsp
	make distclean -C secure_boot/sign_image