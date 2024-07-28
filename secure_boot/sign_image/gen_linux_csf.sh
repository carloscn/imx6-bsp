#!/bin/bash

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 -f <input_file> -o <output_file>"
    exit 1
fi

while getopts ":f:o:" opt; do
    case $opt in
        f) input_file="$OPTARG"
        ;;
        o) output_file="$OPTARG"
        ;;
        \?) echo "[ERR] Invalid option -$OPTARG" >&2
            exit 1
        ;;
    esac
done

ZIMAGE=${input_file}
GENIVT=genIVT
IVT_BIN=ivt.bin
ZIMAGE_PAD_BIN=zImage-pad.bin
ZIMAGE_PAD_IVT_BIN=zImage-pad-ivt.bin

# Get zImage file size and check for errors
ZIMAGE_SIZE=$(stat -c%s "$ZIMAGE")
if [ $? -ne 0 ] || [ "$ZIMAGE_SIZE" -eq 0 ]; then
    echo "[ERR] Failed to get zImage size or size is 0"
    exit 1
fi

NEXT_4KB_BOUNDARY=$(( (ZIMAGE_SIZE + 0xFFF) & ~0xFFF ))
NEXT_4KB_BOUNDARY_HEX=$(printf "0x%X" $NEXT_4KB_BOUNDARY)
IMAGE_SIZE_HEX=$(printf "0x%X" $ZIMAGE_SIZE)

echo "[INFO] original size = ${IMAGE_SIZE_HEX}"
echo "[INFO] round up to next 4K = ${NEXT_4KB_BOUNDARY_HEX}"

KERNEL_LOAD_ADDR=0x80800000
KERNEL_JUMP_ADDR=$((KERNEL_LOAD_ADDR + 0x1000))
SELFPOINTER_ADDR=$((KERNEL_LOAD_ADDR + NEXT_4KB_BOUNDARY_HEX))
CSFPOINTER_ADDR=$((SELFPOINTER_ADDR + 0x20))

KERNEL_JUMP_ADDR_HEX=$(printf "0x%X" $KERNEL_JUMP_ADDR)
SELFPOINTER_ADDR_HEX=$(printf "0x%X" $SELFPOINTER_ADDR)
CSFPOINTER_ADDR_HEX=$(printf "0x%X" $CSFPOINTER_ADDR)

echo "[INFO] >>>    KERNEL_LOAD_ADDR:       $KERNEL_LOAD_ADDR"
echo "[INFO] >>>    KERNEL_JUMP_ADDR:       $KERNEL_JUMP_ADDR_HEX"
echo "[INFO] >>>    SELFPOINTER_ADDR:       $SELFPOINTER_ADDR_HEX"
echo "[INFO] >>>    CSFPOINTER_ADDR:        $CSFPOINTER_ADDR_HEX"

cat <<EOF > $GENIVT
#! /usr/bin/perl -w
use strict;
open(my \$out, '>:raw', 'ivt.bin') or die "Unable to open: \$!";
print \$out pack("V", 0x412000D1); # IVT Header
print \$out pack("V", ${KERNEL_LOAD_ADDR}); # Jump Location
print \$out pack("V", 0x0); # Reserved
print \$out pack("V", 0x0); # DCD pointer
print \$out pack("V", 0x0); # Boot Data
print \$out pack("V", ${SELFPOINTER_ADDR_HEX}); # Self Pointer
print \$out pack("V", ${CSFPOINTER_ADDR_HEX}); # CSF Pointer
print \$out pack("V", 0x0); # Reserved
close(\$out);
EOF

chmod +x $GENIVT
./$GENIVT
# Check genIVT execution result
if [ $? -ne 0 ]; then
    echo "[ERR] Failed to execute genIVT"
    exit 1
fi


# Pad zImage and check objcopy execution result
objcopy -I binary -O binary --pad-to=$NEXT_4KB_BOUNDARY_HEX --gap-fill=0x00 $ZIMAGE $ZIMAGE_PAD_BIN
if [ $? -ne 0 ]; then
    echo "[ERR] objcopy failed"
    exit 1
fi

# Concatenate zImage-pad.bin and ivt.bin
cat $ZIMAGE_PAD_BIN $IVT_BIN > $ZIMAGE_PAD_IVT_BIN

# Check zImage-pad-ivt.bin file size
ZIMAGE_PAD_SIZE=$(stat -c%s "$ZIMAGE_PAD_BIN")
ZIMAGE_PAD_IVT_SIZE=$(stat -c%s "$ZIMAGE_PAD_IVT_BIN")
if [ $? -ne 0 ] || [ "$ZIMAGE_PAD_IVT_SIZE" -eq 0 ]; then
    echo "[ERR] Failed to get zImage-pad-ivt.bin size or size is 0"
    exit 1
fi
hex_size=$(printf '0x%x' "$ZIMAGE_PAD_IVT_SIZE")
no_ivt_hex_size=$(printf '0x%x' "$ZIMAGE_PAD_SIZE")

echo "        #     ------- +-----------------------------+ <-- *load_address: $KERNEL_LOAD_ADDR"
echo "        #         ^   |                             |"
echo "        #         |   |                             |"
echo "        #         |   |                             |"
echo "        #         |   |                             |"
echo "        #         |   |           Image             |"
echo "        # Signed  |   |                             |"
echo "        #  Data   |   |                             |"
echo "        #         |   |                             |"
echo "        #         |   +-----------------------------+ <-- *image size: $IMAGE_SIZE_HEX"
echo "        #         |   |   Padding to Image size     |"
echo "        #         |   |        in header            |  -- *image padded size: $no_ivt_hex_size"
echo "        #         |   |                             | /"
echo "        #         |   +-----------------------------+ <-- *ivt:  $SELFPOINTER_ADDR_HEX"
echo "        #         |   |                             |"
echo "        #         |   |    Image Vector Table       |  -- *image padded + ivt size: $hex_size"
echo "        #         v   |                             | /"
echo "        #     ------- +-----------------------------+ <-- *csf:  $CSFPOINTER_ADDR_HEX"
echo "        #             |                             |"
echo "        #             |   Command Sequence          |"
echo "        #             |   File (CSF)                |"
echo "        #             |                             |"
echo "        #             +-----------------------------+"
echo "        #             |   Padding (optional)        |"
echo "        #             +-----------------------------+"

# Create u-boot.csf content
csf_content=$(cat <<EOF
[Header]
Version = 4.0
Security Configuration = Open
Hash Algorithm = sha256
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS
Engine = SW

[Install SRK]
File = "../certs/SRK_1_2_3_4_table.bin"
Source index = 0

[Install CSFK]
File = "../certs/CSF1_1_sha256_2048_65537_v3_usr_crt.pem"

[Authenticate CSF]

[Install Key]
Verification index = 0
Target index = 2
File = "../certs/IMG1_1_sha256_2048_65537_v3_usr_crt.pem"

[Authenticate Data]
Verification index = 2
Blocks = ${KERNEL_LOAD_ADDR} 0x00000000 ${hex_size} "${ZIMAGE_PAD_IVT_BIN}"

EOF
)

# Write content to output file
echo "$csf_content" > "$output_file"

echo "[INFO] Generated $output_file with file size $hex_size"
echo "[INFO] RUN => hab_auth_img ${KERNEL_LOAD_ADDR} 0xffffff $no_ivt_hex_size in your uboot to verify kernel!"