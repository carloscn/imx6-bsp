
1.Generating a PKI tree
	./hab4_pki_tree.sh
2.Generating a SRK Table and SRK Hash
	../linux64/bin/srktool -h 4 -t SRK_1_2_3_4_table.bin -e \
		SRK_1_2_3_4_fuse.bin -d sha256 -c \
		SRK1_sha256_2048_65537_v3_ca_crt.pem,\
		SRK2_sha256_2048_65537_v3_ca_crt.pem,\
		SRK3_sha256_2048_65537_v3_ca_crt.pem,\
		SRK4_sha256_2048_65537_v3_ca_crt.pem
1.1 Building a u-boot-dtb.imx image supporting secure boot
1.2 Enabling the secure boot support
	CONFIG_IMX_HAB=y
1.3 Creating the CSF description file
	Refer to above, we have keys, certificates, SRK table, and SRK hash generation.
	Block = 0x877ff400 0x00000000 0x0009ec00 "u-boot-dtb.imx"
    You can get the value from
```
  $ cat u-boot-dtb.imx.log

  Image Type:   Freescale IMX Boot Image
  Image Ver:    2 (i.MX53/6/7 compatible)
  Mode:         DCD
  Data Size:    667648 Bytes = 652.00 KiB = 0.64 MiB
  Load Address: 877ff420
  Entry Point:  87800000
  HAB Blocks:   0x877ff400 0x00000000 0x0009ec00
                ^^^^^^^^^^ ^^^^^^^^^^ ^^^^^^^^^^
                |          |          |
                |          |          ------- (1)
                |          |
                |          ------------------ (2)
                |
                ----------------------------- (3)
  (1)   Size of area in file u-boot-dtb.imx to sign.
        This area should include the IVT, the Boot Data the DCD
        and the U-Boot itself.
  (2)   Start of area in u-boot-dtb.imx to sign.
  (3)   Start of area in RAM to authenticate.
```

1.3.1 Avoiding Kernel crash when OP-TEE is enabled
	- Add Unlock MID command in CSF:
	[Unlock]
		Engine = CAAM
		Features = MID
1.4 Signing the U-Boot binary
	The CST tool is used for singing the U-Boot binary and generating a CSF binary,
	users should input the CSF description file created in the step above and should
	receive a CSF binary, which contains the CSF commands, SRK table,signatures and certificates.
	- Create CSF binary file:
		$ ./cst -i csf_uboot.txt -o csf_uboot.bin
	- Append CSF signature to the end of U-Boot image:
		$ cat u-boot-dtb.imx csf_uboot.bin > u-boot-signed.imx
	The u-boot-signed.imx is the signed binary and should be flashed into the boot media.
	- Flash signed U-Boot binary:
		$ sudo dd if=u-boot-signed.imx of=/dev/sd<x> bs=1K seek=1 && sync
1.5 Programming SRK Hash
	the SRK Hashfuse values are generated by the srktool and should be programmed in the SoC
	SRK_HASH[255:0] fuses.
	The U-Boot fuse tool can be used for programming eFuses on i.MX SoCs.
	- Dump SRK Hash fuses values in host machine:
		$ hexdump -e '/4 "0x"' -e '/4 "%X""\n"' SRK_1_2_3_4_fuse.bin
		  0x20593752
		  0x6ACE6962
		  0x26E0D06C
		  0xFC600661
		  0x1240E88F
		  0x1209F144
		  0x831C8117
		  0x1190FD4D
	- Program SRK_HASH[255:0] fuses, using i.MX6 series as example:
		  => fuse prog 3 0 0x20593752
		  => fuse prog 3 1 0x6ACE6962
		  => fuse prog 3 2 0x26E0D06C
		  => fuse prog 3 3 0xFC600661
		  => fuse prog 3 4 0x1240E88F
		  => fuse prog 3 5 0x1209F144
		  => fuse prog 3 6 0x831C8117
		  => fuse prog 3 7 0x1190FD4D
1.6 Verifying HAB events
	- Verify HAB events:
	  => hab_status
	  Secure boot disabled

	  HAB Configuration: 0xf0, HAB State: 0x66
	  No HAB Events Found!
1.7 Closing the device
	- Program SEC_CONFIG[1] fuse, using i.MX6 series as example:
	=> fuse prog 0 6 0x00000002

