# !/bin/bash

bash enable_secure_boot.sh \
    -u u-boot_signed.imx \
    -k zImage_signed \
    -r zImage_mfgtool_signed \
    -h SRK_1_2_3_4_fuse.bin