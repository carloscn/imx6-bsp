.PHONY: clean distclean all

UBOOT_IMX_FILE=u-boot.imx
LINUX_IMX_FILE=zImage
SRK_TABLE=../certs/SRK_1_2_3_4_table.bin
UBOOT_IMG_CERT=../certs/IMG1_1_sha256_2048_65537_v3_usr_crt.pem
UBOOT_CSF_CERT=../certs/CSF1_1_sha256_2048_65537_v3_usr_crt.pem
LINUX_IMG_CERT=../certs/IMG2_1_sha256_2048_65537_v3_usr_crt.pem
LINUX_CSF_CERT=../certs/CSF2_1_sha256_2048_65537_v3_usr_crt.pem
# Targets
all: sign_uboot sign_linux

$(UBOOT_IMX_FILE):
	@echo "[ERR] please place the file of [$(UBOOT_IMX_FILE)] on this path!" ; false

$(LINUX_IMX_FILE):
	@echo "[ERR] please place the file of [$(LINUX_IMX_FILE)] on this path!" ; false

$(UBOOT_IMG_CERT):
	@echo "[ERR] please place the file of [$(UBOOT_IMG_CERT)] on this path!" ; false

$(UBOOT_CSF_CERT):
	@echo "[ERR] please place the file of [$(UBOOT_CSF_CERT)] on this path!" ; false

$(LINUX_IMG_CERT):
	@echo "[ERR] please place the file of [$(LINUX_IMG_CERT)] on this path!" ; false

$(LINUX_CSF_CERT):
	@echo "[ERR] please place the file of [$(LINUX_CSF_CERT)] on this path!" ; false

$(SRK_TABLE):
	@echo "[ERR] please place the file of [$(SRK_TABLE)] on this path!" ; false

sign_uboot: $(UBOOT_IMX_FILE) $(UBOOT_IMG_CERT) $(UBOOT_CSF_CERT) $(SRK_TABLE)
	@mkdir -p certs
	@echo "[INFO] gen the csf config file according to the $(UBOOT_IMX_FILE)!"
	@./gen_uboot_csf.sh -f $(UBOOT_IMX_FILE) -o u-boot-gen.csf
	@echo "[INFO] gen the CSF header binary and sign the u-boot image!"
	@./cst --o u-boot_csf.bin --i u-boot-gen.csf
	@echo "[INFO] generate the bootable image!"
	@cat $(UBOOT_IMX_FILE) u-boot_csf.bin > u-boot_signed.imx
	@echo "[INFO] done! The output is [u-boot_signed.imx]"

sign_linux: $(LINUX_IMX_FILE) $(LINUX_IMG_CERT) $(LINUX_CSF_CERT) $(SRK_TABLE)
	@echo "[INFO] gen the csf config file according to the $(LINUX_IMX_FILE)!"
	@./gen_linux_csf.sh -f $(LINUX_IMX_FILE) -o zImage-gen.csf
	@echo "[INFO] gen the CSF header binary and sign the u-boot image!"
	@./cst --o zImage_csf.bin --i zImage-gen.csf
	@echo "[INFO] generate the bootable image!"
	@cat zImage-pad-ivt.bin zImage_csf.bin > zImage_signed
	@echo "[INFO] done! The output is [zImage_signed]"

distclean: clean
	@rm -rf $(UBOOT_IMX_FILE)
	@rm -rf $(LINUX_IMX_FILE)

clean:
	@rm -rf u-boot-gen.csf u-boot_csf.bin u-boot_signed.imx certs u-boot.csf uboot.csf
	@rm -rf zImage_csf.bin zImage-pad-ivt.bin zImage_signed zImage-pad.bin zImage-gen.csf zImage.csf ivt.bin linux-gen.csf genIVT
	@echo "clean all output!"

# Phony targets
.PHONY: clean distclean
