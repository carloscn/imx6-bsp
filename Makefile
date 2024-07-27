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

clean:
	make clean -C bsp
	make clean -C secure_boot/sign_image

distclean:
	make distclean -C bsp
	make distclean -C secure_boot/sign_image